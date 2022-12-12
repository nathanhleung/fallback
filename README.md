# fallback()

A Solidity web framework / a proof-of-concept of HTTP over Ethereum.

## Running

### Forge Script

Run `forge script script/HttpServer.s.sol`

### Over HTTP

Run `anvil`, then grab one of the generated private keys.

Then run `forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY src/HttpServer.sol:HttpServer` and grab the contract address.

Then run `ADDRESS=$ADDRESS node index.js`

## How It Works

Deploy `HttpServer.sol:HttpServer` as a contract. Then send a transaction to the contract with a UTF-8 hex-encoded HTTP request as data. The returned data will be an HTTP response.

### Example

```js
const jsonRpcData = JSON.stringify({
  jsonrpc: "2.0",
  id: "1",
  method: "eth_call",
  params: [
    {
      to: CONTRACT_ADDRESS,
      data: Buffer.from(
        "GET / HTTP/1.1\n" +
          "Host: 127.0.0.1\n" +
          "Accept-Language: en-US,en\n",
        "utf-8"
      ).toString("hex"),
    },
  ],
});
```
