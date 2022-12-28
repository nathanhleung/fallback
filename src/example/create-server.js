const http = require("http");
const https = require("https");
const net = require("net");
const { URL } = require("url");

const ETHEREUM_RPC_URL =
  process.env.ETHEREUM_RPC_URL || "http://127.0.0.1:8545";

/**
 * Sends a JSON-RPC request to the Ethereum RPC.
 * @param {*} jsonRpcData The JSON-RPC request (an object
 *     which will be `JSON.stringify`'d)
 * @returns The JSON-RPC response, `JSON.parse`d.
 */
function sendJsonRpcRequest(jsonRpcData) {
  return new Promise((resolve) => {
    const rpcUrl = new URL(ETHEREUM_RPC_URL);

    const requestOptions = {
      host: rpcUrl.hostname,
      path: rpcUrl.pathname,
      port: rpcUrl.port,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
    };

    let request;
    if (rpcUrl.protocol == "https") {
      request = https.request(requestOptions, handleResponse);
    } else {
      request = http.request(requestOptions, handleResponse);
    }

    function handleResponse(response) {
      let responseData = "";
      response.on("data", (chunk) => (responseData += chunk));
      response.on("end", () => resolve(JSON.parse(responseData)));
    }

    request.write(JSON.stringify(jsonRpcData));
    request.end();
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
