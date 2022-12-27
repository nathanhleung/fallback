---
sidebar_position: 5
---

# Acknowledgments

The idea of using the `fallback()` function to pass arbitrary data to a smart contract came from [Gnosis Safe](https://safe.global/).

> While contracting for a crypto wallet startup last month, one of my tasks was adding [EIP-1271](https://eips.ethereum.org/EIPS/eip-1271) validation support to the startup's wallet SDK. The startup's wallet was based on the [Gnosis Safe code](https://github.com/safe-global/safe-contracts). As I was reading the safe contract, I saw that [`GnosisSafe`](https://github.com/safe-global/safe-contracts/blob/main/contracts/GnosisSafe.sol) extended a contract called [`FallbackManager`](https://github.com/safe-global/safe-contracts/blob/main/contracts/base/FallbackManager.sol), which allowed a contract developer to arbitrarily swap out the implementation of the `GnosisSafe`'s `fallback` function. This got me thinking about what a `fallback` function with more complex logic could do.

The idea to implement HTTP over Ethereum/Solidity was inspired by reading about [DNS tunneling (i.e. HTTP over DNS) to get free in-flight Wi-Fi](https://medium.com/@galolbardes/learn-how-easy-is-to-bypass-firewalls-using-dns-tunneling-and-also-how-to-block-it-3ed652f4a000).

More broadly, the idea that smart contracts could have arbitrary input interfaces, beyond the standard protocols output by the Solidity compiler (i.e. the use of function selectors to control which contract function is executed), was inspired by the [MagicNumber Ethernaut level](https://ethernaut.openzeppelin.com/level/0xBE732789f2963E0522719F2D3fB55E6bfe07e92e), where the solution is a bytecode-only contract which always returns the number `42` .

Finally, the API of the HTML DSL was inspired by [HyperScript](https://github.com/hyperhype/hyperscript) and [Pug](https://github.com/pugjs/pug).
