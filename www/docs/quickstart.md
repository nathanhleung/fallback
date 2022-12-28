---
sidebar_position: 1
---

# Quick Start

Here's how you can create your own fallback() Solidity web app and expose it to the web.

## 1. Extend <code>WebApp</code>

Create a new file called `MyApp.sol` and extend the `WebApp` contract.

The GitHub imports in the code samples below will work on [Remix](https://remix.ethereum.org/); you may need to change the URL imports to relative imports if you're developing locally and you cloned the [fallback repository](https://github.com/nathanhleung/fallback) or installed fallback() with [Forge](https://github.com/foundry-rs/foundry/tree/master/forge).

```solidity title="MyApp.sol"
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";
// If you're using Foundry, you might need to import `WebApp` with
// import {WebApp} from "lib/fallback/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
    }

    // You'll write your fallback() app's routes here!
}
```

## 2. Add your routes

Import the `HttpConstants` contract and add your routes to the `routes` mapping, specifying the correct HTTP `method` and `path`.

The `routes` mapping is defined in the `WebApp` contract.

```solidity title="MyApp.sol" showLineNumbers
// highlight-start
import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        // highlight-start
        // A `GET` request to `/` will be handled by the `getIndex` function
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        // A `GET` request to `/github` will be handled by the `getGithub` function
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
        // highlight-end
    }
}
```

## 3. Create contract functions for your routes

Create functions in the `MyApp` contract to handle your routes. Make sure the function signature of each route handler is `functionName(HttpMessages.Request)` or `functionName()` (if your route handler doesn't need access to the `Request` struct).

Your route handler function can have pretty much any name (as long as it doesn't overlap with one of `WebApp`'s response helper functions like `json` or `html`; more on this below).

Always make sure your route handler function has the correct function signature and the route handler function's name is typed correctly in the `routes` mapping.

```solidity
// Any typo will not work!
routes[HttpConstants.Method.GET]["/"] = "getInndex";

// This will not work! Try putting `extraData` into a request header
// or request content instead.
function getIndex(HttpMessages.Request calldata request, bool extraData)
```

> Internally, fallback() will parse incoming HTTP requests and use the `routes` mapping to determine which contract function to call. It will call the function using its [function selector](https://solidity-by-example.org/function-selector/), which depends on the function's parameters.
>
> If your route handler functions don't have the correct function signature, fallback() will generate an incorrect function selector and your route handler function won't be called.

```solidity title="MyApp.sol" showLineNumbers
import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
// highlight-start
import {HttpMessages} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    // highlight-start
    function getIndex(HttpMessages.Request calldata request) external pure override returns (HttpMessages.Response memory) {
    }
    // highlight-end

    // highlight-start
    function getGithub() external pure returns (HttpMessages.Response memory) {
    }
    // highlight-end
}
```

## 4. Implement your routes

Implement your route handlers in `MyApp.sol`. You can import `H`, fallback()'s companion Solidity HTML DSL, and use the `html` function to return an HTML response.

The full list of available `WebApp` response helpers (e.g. `text`, `json`, `redirect`) is in the [API Reference](/docs/api). You can also build an `HttpMessages.Response` struct from scratch and return that.

> The response helpers build `HttpMessages.Response` instances with specific headers (e.g. the `json` response helper function builds a `Response` with a `Content-Type: application/json` header).
>
> These response helpers are defined on `WebApp`, so you cannot create route handler functions with names matching any of the response helpers; the Solidity compiler will output an error (since the response helper functions are not marked `virtual`).

```solidity title="MyApp.sol" showLineNumbers
// highlight-start
import {H} from "https://github.com/nathanhleung/fallback/blob/main/src/html-dsl/H.sol";
// highlight-end
import {HttpConstants} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpConstants.sol";
import {HttpMessages} from "https://github.com/nathanhleung/fallback/blob/main/src/http/HttpMessages.sol";
// highlight-start
import {StringConcat} from "https://github.com/nathanhleung/fallback/blob/main/src/strings/StringConcat.sol";
// highlight-end
import {WebApp} from "https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol";

contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    // highlight-start
    function getIndex(HttpMessages.Request calldata request) external pure override returns (HttpMessages.Response memory) {
        // The `H` API is heavily based on
        // https://github.com/hyperhype/hyperscript
        // and Jade/Pug
        // https://github.com/pugjs/pug
        // Use `H.element` (if standard HTML tag) or H.h("element")
        // to generate an `<element>`.
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
    // highlight-end

    // highlight-start
    function getGithub() external pure returns (HttpMessages.Response memory) {
        return redirect(302, "https://github.com/nathanhleung/fallback");
    }
    // highlight-end
}
```

## 5. Pass your app to the <code>DefaultServer</code> contract

Once you've implemented your route handlers, create a new contract `MyServer` which extends `DefaultServer`. Pass an instance of `MyApp` to `DefaultServer`'s constructor.

> `DefaultServer` extends the `HttpServer` contract and automatically sets a few reasonable request parsing defaults (e.g. it sets `maximumRequestHeaders` to `4000` and `maxPathLength` to `4000`). These defaults are generally [based on Apache's defaults](https://stackoverflow.com/questions/1289585/what-is-apaches-maximum-url-length).
>
> If you want to customize request parsing behavior, you can construct your own instance of `HttpServer` separately, but the `DefaultServer` should suffice for most use-cases.

```solidity title="MyServer.sol" showLineNumbers
import {DefaultServer} from "https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol";
import {MyApp} from "./MyApp.sol";

contract MyServer is DefaultServer {
    constructor() DefaultServer(new MyApp()) {
        app.setDebug(true);
    }
}
```

## 6. Deploy <code>MyServer</code>

Then, compile and deploy the `MyServer` contract.

The deployment example below uses [Foundry](https://github.com/foundry-rs/foundry)'s [Forge](https://github.com/foundry-rs/foundry/tree/master/forge), but you could also use other tools like [Remix](https://remix.ethereum.org/) or [Hardhat](https://hardhat.org/) to deploy your contract.

```shell title="Terminal"
forge create MyServer.sol:MyServer
```

## 7. Send HTTP requests to the contract

When you send HTTP requests to the `MyServer` contract (hex-encode the requests into the `data` field of a transaction), the return value will be a hex-encoded HTTP response.

The sample below shows how to send a request to the contract using native Node.js modules (it uses `eth_call` internally, so it doesn't make any changes to blockchain state).

```javascript title="request.js" showLineNumbers
const http = require("http");

// Construct JSON-RPC request
const jsonRpcData = JSON.stringify({
  jsonrpc: "2.0",
  id: "1",
  method: "eth_call",
  params: [
    {
      to: CONTRACT_ADDRESS,
      // HTTP request to send to contract
      data: "GET / HTTP/1.1".toString("hex"),
    },
  ],
});

// Send JSON-RPC request
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
  // Receive response
  (response) => {
    let responseData = "";
    response.on("data", (chunk) => (responseData += chunk));
    response.on("end", () => {
      const responseJson = JSON.parse(responseData);
      const responseBytes = Buffer.from(responseJson.result.slice(2), "hex");
      console.log(responseBytes.toString());
      // HTTP/1.1 200 OK
      // Server: fallback()
      // Content-Type: text/html
      // ...
    });
  }
);
httpRequest.write(jsonRpcData);
httpRequest.end();
```

## 8. Expose your fallback() app to the web

To expose your fallback() app to the web, you'll need to create a TCP server that can pass messages to and from the deployed contract on the blockchain.

Here's a Node.js example, using only native modules, which exposes a fallback() web app on port 8000.

```javascript title="server.js" showLineNumbers
const http = require("http");
const net = require("net");

const ETHEREUM_RPC_HOST = process.env.ETHEREUM_RPC_HOST || "127.0.0.1";
const ETHEREUM_RPC_PORT = process.env.ETHEREUM_RPC_PORT || 8545;

// MyServer contract address
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;

const server = net.createServer((socket) => {
  socket.on("data", async (requestData) => {
    // Receive and parse contract response
    let response = JSON.parse(await handleRequest(requestData));

    try {
      if (response.result.length > 0) {
        // Decode contract response
        const responseData = Buffer.from(response.result.slice(2), "hex");
        // Send contract response back
        socket.write(responseData.toString());
      }
      socket.end();
    } catch (err) {
      console.error(response);
      console.error(err.toString());
      socket.end();
    }
  });
});

server.listen(8000, "0.0.0.0", () => {
  console.log("Server running at localhost:8000");
});

async function handleRequest(requestData) {
  return new Promise((resolve) => {
    const jsonRpcData = JSON.stringify({
      jsonrpc: "2.0",
      id: "1",
      method: "eth_call",
      params: [
        {
          to: CONTRACT_ADDRESS,
          // Forward TCP data to contract
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
        // Receive contract return data over JSON-RPC
        response.on("data", (chunk) => (responseData += chunk));
        // Send contract return data back to caller
        response.on("end", () => resolve(responseData));
      }
    );
    httpRequest.write(jsonRpcData);
    httpRequest.end();
  });
}
```

> See [`send-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/send-server.js) for an example of how to write a server that modifies blockchain state using `eth_send*` methods. In this case, instead of getting the data returned from the call and sending it back as the HTTP response, you need to extract the data from the `Response` event (defined in [`HttpProxy`](https://github.com/nathanhleung/fallback/blob/main/src/http/HttpProxy.sol)) after the transaction is included in a block. The initial return value after sending the transaction will just be the transaction hash.

To put this into production, you could run this script on an AWS EC2 instance and [use NGINX as a reverse proxy to forward requests from port 80 to 8000](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-node-js-application-for-production-on-ubuntu-20-04).

You could also add HTTPS support by [configuring NGINX with Let's Encrypt](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-20-04).

Another alternative is HAProxy, which [supports proxying over both TCP and HTTP](https://www.haproxy.com/blog/layer-4-and-layer-7-proxy-mode/). You could use [HAProxy's connection limiting, queueing](https://www.haproxy.com/blog/protect-servers-with-haproxy-connection-limits-and-queues/), [caching](https://www.haproxy.com/blog/accelerate-your-apis-by-using-the-haproxy-cache/), and [rate-limiting features](https://www.haproxy.com/blog/four-examples-of-haproxy-rate-limiting/) to control the load on your blockchain RPCs.

See the [`Dockerfile`](https://github.com/nathanhleung/fallback/blob/main/src/example/Dockerfile) in `src/example` for an example one-container setup with HAProxy for caching and rate limiting.

## 9. Next steps

You can write any sort of web app with fallback().

For more fallback() web app examples, with more advanced route handlers, see [`src/example/SimpleExample.sol`](https://github.com/nathanhleung/fallback/blob/main/src/example/FullExample.sol) and [`src/example/FullExample.sol`](https://github.com/nathanhleung/fallback/blob/main/src/example/FullExample.sol).

Here's an excerpt based on one of the example apps showing how to handle a `POST` request:

```solidity title="ExamplePostApp.sol" showLineNumbers
contract ExamplePostApp is WebApp {
    constructor() {
        // Call different handlers based on HTTP method
        routes[HttpConstants.Method.GET]["/form"] = "getForm";
        routes[HttpConstants.Method.POST]["/form"] = "postForm";
    }

    // Show cURL `POST` command if `GET` request
    function getForm() external pure returns (HttpMessages.Response memory) {
        HttpMessages.Response memory response;
        response
            .content = "curl -v -d 'random post data' -X POST http://localhost:8000/form";
        return response;
    }

    // Send `POST`ed data back
    function postForm(HttpMessages.Request calldata request)
        external
        pure
        returns (HttpMessages.Response memory)
    {
        HttpMessages.Response memory response;
        response.content = StringConcat.concat(
            "Received posted data: ",
            string(request.content)
        );
        return response;
    }
}
```

For a working Node.js TCP server example, see [`call-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/call-server.js) in the `src/example` directory.

Finally, see [`src/example/Todo.sol`](https://github.com/nathanhleung/fallback/blob/main/src/example/Todo.sol) for a working todo app. If run with the [`send-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/send-server.js) server, this app demonstrates reading and writing state to the blockchain over HTTP.

## Appendix: Live Demos

There are fallback() contracts live on the Goerli Optimism testnet.

An instance of [`SimpleExampleServer`](https://github.com/nathanhleung/fallback/blob/main/src/example/SimpleExample.sol) is deployed at [**0x83707e88a05046A04B459d8D0eB1aFcC404f92eB**](https://goerli-optimism.etherscan.io/address/0x83707e88a05046A04B459d8D0eB1aFcC404f92eB) and served with [`call-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/call-server.js) at http://simple.fallback.natecation.xyz.

An instance of [`TodoServer`](https://github.com/nathanhleung/fallback/blob/main/src/example/Todo.sol) is deployed at [**0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3**](https://goerli-optimism.etherscan.io/address/0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D3) and served with [`send-server.js`](https://github.com/nathanhleung/fallback/blob/main/src/example/send-server.js) at http://todo.fallback.natecation.xyz.

> Privacy note: the todo demo logs all incoming HTTP requests to the blockchain. See the input data on [the todo contract on Etherscan](https://goerli-optimism.etherscan.io/address/0x919F31dAC93eBf9fFd15a54acd13082f34fDd6D31) to see an example of the type of data that is logged. Please do not visit the page if you are not comfortable with this; see the simple demo instead, which is read-only.

> If http://todo.fallback.natecation.xyz isn't working, the sender account is probably out of Optimistic Goerli ETH. Try again later when I've sent it more, or donate some to [0xDB922AA1571aBCEc925221B7B6E9F9db4edDC625](https://goerli-optimism.etherscan.io/address/0xDB922AA1571aBCEc925221B7B6E9F9db4edDC625)!
