/**
 * A server which forwards HTTP requests to the
 * smart contract and gets responses using `eth_call`.
 */
const { sendJsonRpcRequest, createServer } = require("./create-server");

const PORT = process.env.PORT || 8000;
const FALLBACK_SERVER_CONTRACT_ADDRESS =
  process.env.FALLBACK_SERVER_CONTRACT_ADDRESS;

async function requestHandler(requestData) {
  try {
    const result = await sendJsonRpcRequest({
      jsonrpc: "2.0",
      id: "1",
      method: "eth_call",
      params: [
        {
          to: FALLBACK_SERVER_CONTRACT_ADDRESS,
          data: `0x${requestData}`,
        },
      ],
    });

    // Remove leading "0x"
    return result.slice(2);
  } catch (err) {
    console.error(JSON.stringify(err));
    return "";
  }
}

const server = createServer(requestHandler);
server.listen(PORT, "0.0.0.0", () => {
  console.log(`fallback() server running at localhost:${PORT}`);
});
