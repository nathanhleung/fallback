# [fallback()](https://fallback.natecation.xyz)

https://fallback.natecation.xyz

Write web apps in Solidity — **fallback()** is a Solidity web framework / a proof-of-concept implementation of HTTP over Ethereum.

See the [fallback() docs]() for more information:

- [Quick Start](https://fallback.natecation.xyz/docs/quickstart)
- [How it Works](https://fallback.natecation.xyz/docs/how-it-works)
- [API Reference](https://fallback.natecation.xyz/docs/api)
- [Roadmap](https://fallback.natecation.xyz/docs/roadmap)
- [Acknowledgments](https://fallback.natecation.xyz/docs/acknowledgments)

## Repository Structure

- `script/`: Forge scripts
- `src/`: Contract source code

  - `example/`: Example fallback() web apps

    - `SimpleExample.sol`: Simple example app
    - `FullExample.sol`: Example app with prettier HTML responses
    - `create-server.js`: Base TCP server creation logic
    - `call-server.js`: Example TCP-to-blockchain fallback() server implementation that uses `eth_call`
    - `send-server.js`: Example TCP-to-blockchain fallback() server implementation that uses `eth_sendTransaction`
      > This server requires `ethers` as a dependency; run `npm install` first.
    - `Dockerfile`: Example one-container Docker setup with server + HAProxy for rate limiting

  - `html-dsl/`: Solidity HTML DSL contracts
    - `generate-dsl.js`: Script which generates a Solidity DSL function for each valid HTML element
    - `H.sol`: Public API of Solidity HTML DSL
  - `http/*.sol`: Internal framework code related to HTTP parsing/handling
  - `integers/*.sol`: Integer libraries (e.g. integer-to-string code)
  - `strings/*.sol`: String libraries (e.g. string concatenation, string comparison, etc.)
  - `HttpServer.sol`: Extend the `HttpServer` or `DefaultServer` contracts with a `WebApp` to create a Solidity HTTP server
  - `WebApp.sol`: Extend this contract to define routes in a custom web app

- `www/`: Docusaurus docs website

## Testing

### Unit

Forge unit tests are located in `test/` directories, colocated with source code under `src/`.

Run tests with `forge test --match-path "src/**/*.t.sol" -vvvvv"`.

### Integration

To test that all the Solidity contracts work together, run `forge script script/HttpServer.s.sol`.

This script sends some example requests to the `FullExampleServer` in `src/example/FullExample.sol` and prints the output.

### End-to-End

To test that the contracts work when deployed, run `anvil` to start a local testnet, then grab one of the generated private keys.

Deploy the example web app server with `forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY src/example/FullExample.sol:FullExampleServer` and grab the contract address.

Then run `CONTRACT_ADDRESS=$CONTRACT_ADDRESS node src/example/server.js`.

A TCP server will be started at http://localhost:8000 that will forward HTTP requests to the local deployment of the contract.

The server will return the data returned by the contract over TCP as well.
