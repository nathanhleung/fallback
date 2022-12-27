---
sidebar_position: 4
---

# Roadmap

Here are some areas of improvement and questions to think about for the next version of fallback(). Contributions are always welcome!

## Tests

As of this writing, test coverage is pretty limited. The parts of fallback() that are in greatest need of better tests are:

- the utility libraries — those in `src/integers/` and `src/strings/`
- the core HTTP request parsing code in `HttpMessages.sol`.

  > While `HttpMessages.sol` generally seems to perform well on simple, well-formed requests, its performance on malformed and more complex HTTP requests isn't well-tested.

## Gas Optimization

The initial fallback() code was written with limited attention to gas optimization, and there are likely many places in the contracts where gas usage could be cut down. For example:

- `StringConcat.sol` — in many cases, the `StringConcat.concat` function is just used to create intermediate strings which are subsequently concatenated again. Is it possible to "concatenate by reference" and only allocate a new string once the final concatenated result needs to be used?

## Security

There's a [Solhint](https://github.com/protofire/solhint) rule called [`no-complex-fallback`](https://github.com/protofire/solhint/blob/master/docs/rules/security/no-complex-fallback.md), under the "Security" category, which encourages the `fallback` function to have less than 2 statements.

- What are the security implications of making the `fallback` function so complex and open-ended in this project?

## Examples and Documentation

Some ideas for improvements in documentation or examples:

- Would it be possible to write TodoMVC or something similar using fallback()?
- Are there any other canonical web app examples we could implement in fallback()?

## Code Clarity

There are places in the code where it isn't exactly clear why something is working (but it still seems to work fine!). For example:

- It is unclear why the `fallback` function in `WebApp.sol` needs to return 32 extra bytes for `safeCallApp` in `HttpHandler.sol` to receive the 404 response correctly when a nonexistent route handler function is called (when the 32 bytes aren't added, ABI-decoding the returned data into an `HttpMessage.Response` in `safeCallApp` fails).

  > Author's note: As I was developing the `fallback` function in `WebApp` and trying to figure out why ABI-decoding was failing in `safeCallApp` on `HttpHandler`, I decided to compare the returndata of `fallback` (again, on `WebApp` — not the main `fallback` function on `HttpProxy`) to that of a function which already existed on `WebApp`.
  >
  > I noticed that when an existing function on `WebApp` was called, the returned data had 32 extra bytes at the end versus the returned data from the `fallback` function on `WebApp`. So I changed the assembly to return 32 extra bytes from `fallback` on `WebApp`. Once I did that, `safeCallApp` on `HttpHandler` started decoding the return value correctly into an `HttpMessage.Response`.
  >
  > The exact reason why these bytes needed to be added probably has something to do with the specifics of the `return` opcode and the ABI encoding spec for dynamic `bytes` arrays, but (simply content with it just working for now) I haven't looked deeply enough to figure out the specific reasons why.
