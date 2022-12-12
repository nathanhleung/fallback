# fallback()

A Solidity web framework / a proof-of-concept of HTTP over Ethereum.

## Getting Started

To create a new web app, extend the `WebApp` contract.

```solidity
contract MyApp is WebApp {
    constructor() {
        // Add routes here
        routes[HttpMessages.Method.GET]["/"] = "getIndex";
    }

    // Add the route handler. Make sure it takes both a
    // `string[]` and a `bytes` parameter, even if those
    // parameters aren't used.
    function getIndex(
        string[] memory requestHeaders,
        bytes memory requestContent
    )
        external
        override
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        statusCode = 200;

        responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        responseContent = "<!DOCTYPE html>"
        "<html>"
        "<head><title>Hello World</title></head>"
        "<body><p>What hath god wrought?</p></body>"
        "</html>";

        return (statusCode, responseHeaders, responseContent);
    }
}
```

To override the default 404 and error pages, override the `handle*` functions in `WebApp`.

Then, extend the `HttpServer` contract and pass it the web app.

```solidity
contract MyServer is HttpServer {
    constructor() HttpServer(new MyApp()) {
      app.setDebug(true);
    }
}
```

Deploy `MyServer`, then send it HTTP request bytes in the `data` field of a transaction. The return value will be the bytes of a HTTP response.

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

## Pubic API

- `HttpServer.sol:HttpServer`: Extend this contract to wrap a `WebApp` in HTTP handling Solidity code
- `WebApp.sol:WebApp`: Extend this contract to define routes in a custom web app
- `utils/H.sol:H`: Solidity HTML DSL

## Repository Structure

- `script`: Forge scripts
- `src`: Contract source code
  - `example`: Example implementation
  - `utils`: Utility libraries/contracts
    - `H.sol`: Solidity HTML DSL
  - `Http.sol`: Internal framework code related to HTTP
  - `HttpServer.sol`: Extend this contract to wrap a `WebApp` in HTTP handling Solidity code
  - `WebApp.sol`: Extend this contract to define routes in a custom web app

## Testing

### Unit Tests

Forge unit tests are located in the `test` directory.

### Integration

To test that all the Solidity contracts work together, run `forge script script/HttpServer.s.sol`.

This script sends some example requests to the `ExampleServer` and prints the output.

### End-to-End

To test that the contracts work when deployed, run `anvil` to start a local testnet, then grab one of the generated private keys.

Deploy the example web app server with `forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY src/example/Example.sol:ExampleServer` and grab the contract address.

Then run `CONTRACT_ADDRESS=$CONTRACT_ADDRESS node server.js`.

A TCP server will be started at http://localhost:8000 that will forward HTTP requests to the local deployment of the contract.

The server will return the data returned by the contract over TCP as well.

## Todo

Gas optimizations
