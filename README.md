# fallback()

A Solidity web framework.

## Testing

### Forge Script

Run `forge script script/HttpServer.s.sol`

### Over HTTP

Run `anvil`, then grab one of the generated private keys.

Then run `forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY src/HttpServer.sol:HttpServer` and grab the contract address.

Then run `ADDRESS=$ADDRESS node index.js`
