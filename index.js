const http = require("http");
const net = require("net");

const CONTRACT_ADDRESS = process.env.ADDRESS;

async function handleRequest(requestData) {
  return new Promise((resolve, reject) => {
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
        host: "127.0.0.1",
        path: "/",
        port: 8545,
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