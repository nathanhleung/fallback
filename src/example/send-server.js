/**
 * A server which forwards HTTP requests to the
 * smart contract and gets responses using an `eth_send*` method
 * (i.e. this server can change blockchain state).
 */
const { ethers } = require("ethers");
const { sendJsonRpcRequest, createServer } = require("./create-server");

// Optimism Goerli
const CHAIN_ID = process.env.CHAIN_ID || 420;
const PORT = process.env.PORT || 8000;
const FALLBACK_SERVER_CONTRACT_ADDRESS =
  process.env.FALLBACK_SERVER_CONTRACT_ADDRESS;

const PAYER_PRIVATE_KEY = process.env.PAYER_PRIVATE_KEY;

async function waitForTransaction(transactionHash) {
  let transactionReceipt = null;
  while (true) {
    transactionReceipt = await sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "4",
      method: "eth_getTransactionReceipt",
      params: [transactionHash],
    });

    if (transactionReceipt) {
      break;
    } else {
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  return transactionReceipt;
}

async function requestHandler(requestData, attempt = 0) {
  try {
    const wallet = new ethers.Wallet(PAYER_PRIVATE_KEY);
    const walletAddress = await wallet.getAddress();

    const baseTransaction = {
      // Fix "only replay-protected (EIP-155) transactions allowed over RPC" error
      // https://docs.alchemy.com/changelog/08252022-removed-support-for-unprotected-transactions
      chainId: CHAIN_ID,
      from: walletAddress,
      to: FALLBACK_SERVER_CONTRACT_ADDRESS,
      data: `0x${requestData}`,
    };

    // Making sure we always have the right nonce is the main blocker for
    // good request concurrency. Some ideas here:
    // https://ethereum.stackexchange.com/questions/39790/concurrency-patterns-for-account-nonce
    const transactionCountRequest = sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "0",
      method: "eth_getTransactionCount",
      params: [walletAddress, "pending"],
    });

    const gasEstimateRequest = sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "1",
      method: "eth_estimateGas",
      params: [baseTransaction],
    });

    const gasPriceRequest = sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "2",
      method: "eth_gasPrice",
      params: [],
    });

    const [transactionCount, gasEstimate, gasPrice] = await Promise.all([
      transactionCountRequest,
      gasEstimateRequest,
      gasPriceRequest,
    ]);

    const signedTransaction = await wallet.signTransaction({
      ...baseTransaction,
      gasLimit: Math.ceil(Number(gasEstimate) * 1.25),
      gasPrice: Number(gasPrice),
      nonce: Number(transactionCount),
    });

    const transactionHash = await sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "3",
      method: "eth_sendRawTransaction",
      params: [signedTransaction],
    });

    const transactionReceipt = await waitForTransaction(transactionHash);

    // Every transaction will emit a `Response` event with the
    // response bytes as part of the event data
    const responseEventData = transactionReceipt.logs[0].data;
    return responseEventData.slice(2);
  } catch (err) {
    // Hacky solution (for now) to handle duplicate nonces
    if (err.error.message.includes("nonce too low") && attempt < 5) {
      // Try again
      console.error("Nonce too low, trying again...");
      // Limit attempts to prevent leaking memory
      return requestHandler(requestData, attempt + 1);
    } else {
      console.error(JSON.stringify(err));
      return "";
    }
  }
}

const server = createServer(requestHandler);
server.listen(PORT, "0.0.0.0", () => {
  console.log(`fallback() server running at localhost:${PORT}`);
});
