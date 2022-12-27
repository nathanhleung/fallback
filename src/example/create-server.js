const http = require("http");
const net = require("net");

const ETHEREUM_RPC_HOST = process.env.ETHEREUM_RPC_HOST || "127.0.0.1";
const ETHEREUM_RPC_PORT = process.env.ETHEREUM_RPC_PORT || 8545;

/**
 * Sends a JSON-RPC request to the Ethereum RPC.
 * @param {*} jsonRpcData The JSON-RPC request
 * @returns The JSON-RPC response
 */
function sendJsonRpcRequest(jsonRpcData) {
  return new Promise((resolve) => {
    const httpRequest = http.request(
      {
        host: ETHEREUM_RPC_HOST,
        path: "/",
        port: ETHEREUM_RPC_PORT,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
      },
      (response) => {
        let responseData = "";
        response.on("data", (chunk) => (responseData += chunk));
        response.on("end", () => resolve(responseData));
      }
    );
    httpRequest.write(jsonRpcData);
    httpRequest.end();
  });
}

/**
 * Creates a TCP server which hex-encodes request data and
 *     forwards it to the given `requestHandler`.
 * @param {*} requestHandler A function which can receive
 *     hex-encoded request data and returns hex-encoded
 *     response data. Can return a `Promise`.
 * @returns The TCP server. Call server.listen(port) to
 *     start it.
 */
function createServer(requestHandler) {
  return net.createServer((socket) => {
    socket.on("data", async (requestData) => {
      let responseData = Buffer.from(
        await requestHandler(requestData.toString("hex")),
        "hex"
      );
      socket.write(responseData.toString());
      socket.end();
    });
  });
}

module.exports = {
  createServer,
  sendJsonRpcRequest,
};
