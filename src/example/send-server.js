const { ethers } = require("ethers");
const { sendJsonRpcRequest, createServer } = require("./create-server");

const PORT = process.env.PORT || 8000;
const FALLBACK_SERVER_CONTRACT_ADDRESS =
  process.env.FALLBACK_SERVER_CONTRACT_ADDRESS;

const PAYER_PRIVATE_KEY = process.env.PAYER_PRIVATE_KEY;

async function requestHandler(requestData) {
  const wallet = new ethers.Wallet(PAYER_PRIVATE_KEY);
  const signedTransaction = await wallet.signTransaction({
    from: await wallet.getAddress(),
    to: FALLBACK_SERVER_CONTRACT_ADDRESS,
    data: `0x${requestData}`,
  });

  const jsonRpcData = JSON.stringify({
    jsonrpc: "2.0",
    id: "1",
    method: "eth_sendRawTransaction",
    params: [signedTransaction],
  });

  const jsonRpcResponse = JSON.parse(await sendJsonRpcRequest(jsonRpcData));

  // Remove leading "0x"
  return jsonRpcResponse.result.slice(2);
}

const server = createServer(requestHandler);
server.listen(PORT, "0.0.0.0", () => {
  console.log(`fallback() server running at localhost:${PORT}`);
});
