/**
 * A server which forwards HTTP requests to the
 * smart contract and gets responses using `eth_sendTransaction`
 * (i.e. this server can change blockchain state).
 */
const { ethers } = require("ethers");
const { sendJsonRpcRequest, createServer } = require("./create-server");

const PORT = process.env.PORT || 8000;
const FALLBACK_SERVER_CONTRACT_ADDRESS =
  process.env.FALLBACK_SERVER_CONTRACT_ADDRESS;

const PAYER_PRIVATE_KEY = process.env.PAYER_PRIVATE_KEY;

async function waitForTransaction(transactionHash) {
  let transactionReceipt = null;
  while (true) {
    transactionReceipt = (
      await sendJsonRpcRequest({
        jsonrpc: "2.0",
        id: "4",
        method: "eth_getTransactionReceipt",
        params: [transactionHash],
      })
    ).result;

    if (transactionReceipt) {
      break;
    } else {
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  return transactionReceipt;
}

async function requestHandler(requestData) {
  const wallet = new ethers.Wallet(PAYER_PRIVATE_KEY);
  const walletAddress = await wallet.getAddress();

  const baseTransaction = {
    from: walletAddress,
    to: FALLBACK_SERVER_CONTRACT_ADDRESS,
    data: `0x${requestData}`,
  };

  const transactionCountRequest = sendJsonRpcRequest({
    jsonrpc: "2.0",
    id: "0",
    method: "eth_getTransactionCount",
    params: [walletAddress, "latest"],
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
    gasLimit: Math.ceil(Number(gasEstimate.result) * 1.25),
    gasPrice: Number(gasPrice.result),
    nonce: Number(transactionCount.result),
  });

  const transactionHash = (
    await sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "3",
      method: "eth_sendRawTransaction",
      params: [signedTransaction],
    })
  ).result;

  const transactionReceipt = await waitForTransaction(transactionHash);

  // Every transaction will emit a `Response` event with the
  // response bytes as part of the event data
  const responseEventData = transactionReceipt.logs[0].data;
  return responseEventData.slice(2);
}

const server = createServer(requestHandler);
server.listen(PORT, "0.0.0.0", () => {
  console.log(`fallback() server running at localhost:${PORT}`);
});
