---
sidebar_position: 2
---

# How It Works

## Summary

Here's a quick high-level summary of how fallback() works. A more in-depth explanation is included further below on this page, under [Full Request/Response Lifecycle](#full-requestresponse-lifecycle).

1. The calling contract or app serializes an HTTP request into bytes. For example:

   ```solidity
   // Convert HTTP request string into bytes in Solidity
   bytes memory requestBytes = bytes("GET /github HTTP/1.1");
   ```

   ```javascript
   // Convert HTTP request string into bytes in Node.js
   const requestBytes = Buffer.from("GET /github HTTP/1.1").toString("hex");
   ```

2. The calling contract or app calls the fallback() server contract with the serialized HTTP request bytes:

   ```solidity
   // Execute low-level call on the fallback() server contract
   (bool success, bytes memory responseBytes) = myServer.call(requestBytes);

   // The fallback() contract should handle arbitrary input,
   // including malformed requests (which should return a 400
   // response) so `success` will generally not be `false` (if
   // it is `false`, it's a bug!).
   ```

3. The calling contract or app can deserialize the response bytes into a valid HTTP response.

   ```solidity
   // Convert bytes into string to read response
   string memory responseString = string(responseBytes);

   // `responseString` will be "HTTP/1.1 200 OK..."
   ```

> Thanks [@gruns](https://github.com/gruns) for suggesting and outlining this summary!

### Example Transaction

Here's a screenshot of the input and output data of [an example transaction](https://goerli-optimism.etherscan.io/tx/0x948d272d235ae351275bf2b7b4766cf13d816062693676cb279f53e8c5459269) served by [`send-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/send-server.js).

This example request is run against an instance of the [`TodoServer`](https://github.com/nathanhleung/fallback/blob/main/src/example/Todo.sol) example fallback() app, which is deployed at [**0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3**](https://goerli-optimism.etherscan.io/address/0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3) on the Goerli Optimism testnet.

### Input Data

![input data](/img/input-data.png)

### Output Data

![output data](/img/output-data.png)

## Full Request/Response Lifecycle

For a more in-depth look at how fallback() works, we can trace through all the contract calls that occur when you send a request to the `MyServer` created in the [Quick Start](/docs/quickstart). An abridged version of the `MyServer` and `MyApp` contracts is reproduced below:

```solidity title="MyApp.sol" showLineNumbers
contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    function getIndex(HttpMessages.Request calldata request) external pure override returns (HttpMessages.Response memory) {
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

    function getGithub() external pure returns (HttpMessages.Response memory) {
        return redirect(302, "https://github.com/nathanhleung/fallback");
    }
}

contract MyServer is DefaultServer {
    constructor() DefaultServer(new MyApp()) {
        app.setDebug(true);
    }
}
```

### 1. `MyServer`

First, we send the hex-encoded bytes of an HTTP request to `MyServer`:

```javascript title="Example Request in JavaScript" showLineNumbers
const request = "GET /github HTTP/1.1";
const result = await web3.eth.call({
  to: MYSERVER_CONTRACT_ADDRESS,
  data: Buffer.from(request).toString("hex");
});
```

`MyServer` has no logic of its own besides its constructor, so when it receives a request, it's actually handled by [`DefaultServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol).

```solidity title="MyServer.sol"
contract MyServer is DefaultServer
```

### 2. [`DefaultServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol)

```solidity title="HttpServer.sol"
contract DefaultServer is HttpServer
```

[`DefaultServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol) also has no signficant logic of its own — it simply extends the [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol) contract and automatically sets a few reasonable request parsing defaults (e.g. it sets `maximumRequestHeaders` to `4000` and `maxPathLength` to `4000`).

> These defaults are generally [based on Apache's defaults](https://stackoverflow.com/questions/1289585/what-is-apaches-maximum-url-length).

So we follow the inheritance chain up to [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol).

### 3. [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol)

```solidity title="HttpServer.sol"
contract HttpServer is HttpProxy
```

[`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol), in turn, extends [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol). [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol) is essentially a public API for [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) since [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) has no constructor.

### 4. [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) Part 1

[`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) is a contract whose only `external` or `public` function is a [`fallback`](https://docs.soliditylang.org/en/v0.8.17/contracts.html#fallback-function) function (hence, the name of this project).

When [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) receives a transaction with `data`, since there are no functions on the contract, the `fallback` function will be called instead.

In the `fallback` function, [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) uses the [`HttpMessages`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol) contract to parse the calldata as if it were an HTTP request and passes the parsed request to [`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol).

```solidity title="HttpProxy.sol" showLineNumbers
// Simplified version of `HttpProxy`
contract HttpProxy {
    HttpHandler internal handler;
    HttpMessages internal messages;

    fallback() external {
        bytes memory requestBytes = msg.data;
        // Parse request
        HttpMessages.Request memory request =
            messages.parseRequest(requestBytes);
        // Call route handler
        HttpMessages.Response memory response =
            handler.handleRoute(request);
        // ...
    }
```

In our case, our original request

```js
const request = "GET /github HTTP/1.1";
```

would be parsed into something that look like this:

```solidity
HttpMessages.Request {
    method: HttpConstants.Method.GET,
    path: "/github",
    headers: [],
    contentLength: 0,
    content: "",
    raw: "0x..."
}
```

### 5. [`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol)

[`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol)'s `handleRoute` function looks at the parsed HTTP method and path and checks to see if there is a corresponding route set in the `routes` mapping in [`WebApp`](https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol) (in our case, `MyApp`).

```solidity title="MyApp.sol" showLineNumbers
contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }
}
```

If there is a route configured, [`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol) executes a low-level call to the configured function on the instance of [`WebApp`](https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol) and forwards the response back to [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/httpServer.sol).

In our case, [`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol) will map our `GET /github` request to the `getGithub` function on `MyApp` and call it.

```solidity title="MyApp.sol" showLineNumbers
function getGithub() external pure returns (HttpMessages.Response memory) {
    return redirect(302, "https://github.com/nathanhleung/fallback");
}
```

The return value from `getGithub` will be passed to `handleRoute`. It will be an `HttpMessages.Response` struct that looks like this:

```solidity
HttpMessages.Response {
    statusCode: 302,
    headers: ["Location: https://github.com/nathanhleung/fallback"],
    content: ""
}
```

### 6. [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol) Part 2

`handleRoute` will return the response back to [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol).

Finally, [`HttpMessages`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol) is used again to serialize the response into `bytes` and return it to the caller.

```solidity title="HttpProxy.sol" showLineNumbers
// Simplified version of `HttpProxy`
contract HttpProxy {
    HttpHandler internal handler;
    HttpMessages internal messages;

    fallback() external {
        bytes memory requestBytes = msg.data;

        // Parse request
        HttpMessages.Request memory request =
            messages.parseRequest(requestBytes);

        // Call route handler
        HttpMessages.Response memory response =
            handler.handleRoute(request);

        // Serialize `Response` struct into HTTP response bytes
        bytes memory responseBytes = messages.buildResponse(response);

        // Emit event so callers can access response data in the
        // transaction receipt, too.
        emit Response(responseBytes);

        return responseBytes;

        // (We're using `return` above for simplicity, but technically, you
        // can't `return` from`fallback` — the above is actually implemented in
        // inline assembly).
    }
```

### 7. Error Handling

The code samples above are slightly simplified and don't show all the error handling code.

If there is no route configured, [`HttpHandler`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpHandler.sol)'s `handleRoute` will return a `404` response.

If an error occurs during request handling, a `400` (Bad Request) or `500` (Internal Server Error) error will be returned depending on where exactly the error occurred (generally, `400` if it's in `HttpProxy` and `500` if it's in `HttpHandler`).

If `debug` mode is enabled on [`WebApp`](https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol), the error pages will show the full request and response data. In `debug` mode, example error pages can be accessed at the paths `/__not_found` (404), `/__bad_request` (400), and `/__error` (500).
