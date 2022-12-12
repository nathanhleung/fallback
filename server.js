const http = require("http");
const net = require("net");

const ETHEREUM_RPC_HOST = process.env.ETHEREUM_RPC_HOST || "127.0.0.1";
const ETHEREUM_RPC_PORT = process.env.ETHEREUM_RPC_PORT || 8545;
const CONTRACT_ADDRESS = process.env.ADDRESS;

async function handleRequest(requestData) {
  return new Promise((resolve) => {
    const jsonRpcData = JSON.stringify({
      jsonrpc: "2.0",
      id: "1",
      method: "eth_call",
      params: [
        {
          to: CONTRACT_ADDRESS,
          data: requestData.toString("hex"),
        },
      ],
    });

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

const server = net.createServer((socket) => {
  socket.on("data", async (requestData) => {
    const response = JSON.parse(await handleRequest(requestData));
    const responseData = Buffer.from(response.result.slice(2), "hex");
    socket.write(responseData.toString());
    socket.end();
  });
});

server.listen(8000, "0.0.0.0", () => {
  console.log("Server running at localhost:8000");
});
