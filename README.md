# fallback()

Write web apps in Solidity.

**fallback()** is a Solidity web framework / a proof-of-concept implementation of HTTP over Ethereum.

## Getting Started

To create a new Solidity web app, extend the `WebApp` contract.

```solidity
contract MyApp is WebApp {
    constructor() {
        // Add routes here
        routes[HttpMessages.Method.GET]["/"] = "getIndex";
    }

    // Add the route handler.
    function getIndex(HttpMessages.Request calldata request) external pure returns (HttpMessages.Response memory) {
        string memory htmlString = H.html5(
            H.body(
                StringConcat.concat(
                    H.h1("fallback() web framework"),
                    H.p(H.i("a solidity web framework"))
                )
            )
        );
        return html(htmlString);
    }
}
```

Then, extend the `DefaultServer` contract and pass it the web app.

```solidity
contract MyServer is DefaultServer {
    constructor() DefaultServer(new MyApp()) {
      app.setDebug(true);
    }
}
```

Deploy `MyServer`, then send it HTTP request bytes in the `data` field of a transaction. The return value will be the bytes of a HTTP response.

## How It Works

When you send a transaction to the deployed `HttpServer` contract with a UTF-8 hex-encoded HTTP request as data, the contract will return a hex-encoded HTTP response.

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
        "GET / HTTP/1.1\r\n" +
          "Host: 127.0.0.1\r\n" +
          "Accept-Language: en-US,en"
      ).toString("hex"),
    },
  ],
});
```

With [Foundry](https://github.com/foundry-rs/foundry/), when we run

```solidity
bytes memory getIndexRequest = bytes(
    "GET / HTTP/1.1\r\n"
    "Host: 127.0.0.1\r\n"
    "Accept-Language: en-US,en\r\n"
);

(, bytes memory getIndexResponseBytes) = address(httpServer).call(
    getIndexRequest
);
console.log(string(getIndexResponseBytes));
```

the output will be

```
HTTP/1.1 200 OK
Server: fallback()
Content-Type: text/html
Date: 1
Content-Length: 1232

<html><head><title>fallback() Web Framework</title><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
// ... more html ...
```

## Public API

- `src/HttpServer.sol:DefaultServer`: Extend this contract to quickly create a Solidity HTTP server from a `WebApp` instance
- `src/HttpServer.sol:HttpServer`: Extend this to customize your HTTP server's request handling behavior (e.g. change maximum headers, path length, etc.)
- `src/WebApp.sol:WebApp`: Extend this contract to define routes in a custom web app
- `src/html-dsl/H.sol:H`: A Solidity HTML DSL

## Repository Structure

- `script/`: Forge scripts
- `test/`: Forge unit tests
- `src/`: Contract source code
  - `example/`: Example web app + HTTP server implementation
  - `html-dsl/`: Solidity HTML DSL contracts
    - `H.sol`: Public API of Solidity HTML DSL
  - `http/*.sol`: Internal framework code related to HTTP
  - `HttpServer.sol`: Extend the `HttpServer` or `DefaultServer` contracts with a `WebApp` to create a Solidity HTTP server
  - `WebApp.sol`: Extend this contract to define routes in a custom web app

## Testing

### Unit Tests

Forge unit tests are located in `test/` directories, colocated with source code in `src/`.

Run tests with `forge test --match-path "src/**/*.t.sol" -vvvvv"`.

### Integration Tests

To test that all the Solidity contracts work together, run `forge script script/HttpServer.s.sol`.

This script sends some example requests to the `ExampleServer` and prints the output.

### End-to-End Tests

To test that the contracts work when deployed, run `anvil` to start a local testnet, then grab one of the generated private keys.

Deploy the example web app server with `forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY src/example/Example.sol:ExampleServer` and grab the contract address.

Then run `CONTRACT_ADDRESS=$CONTRACT_ADDRESS node server.js`.

A TCP server will be started at http://localhost:8000 that will forward HTTP requests to the local deployment of the contract.

The server will return the data returned by the contract over TCP as well.

## Todo

1. Write more tests and make sure they pass
1. Create landing/documentation website
1. Better documentation and examples
1. Better code comments
1. Gas optimizations
