---
sidebar_position: 3
---

# API Reference

Imports are omitted for clarity in the code samples below. However, the relative import locations for each contract are provided in the parentheses to the right of each contract's name.

## Core Contracts

These contracts are part of the core public API of fallback().

### [`DefaultServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol) (`src/HttpServer.sol:DefaultServer`)

Extend this contract to quickly create a Solidity HTTP server from a `WebApp` instance. For example:

```solidity title="MyServer.sol" showLineNumbers
contract MyServer is DefaultServer {
    constructor() DefaultServer(new MyApp()) {
        app.setDebug(true);
    }
}
```

See `WebApp` below for documentation on `debug` mode.

### [`HttpServer`](https://github.com/nathanhleung/fallback/blob/main/src/HttpServer.sol) (`src/HttpServer.sol:HttpServer`)

Extend this to customize your HTTP server's request handling behavior (e.g. change maximum headers, path length, etc.). For example:

```solidity title="CustomServer.sol" showLineNumbers
contract CustomServer is HttpServer {
    function customHttpMessagesOptions()
        internal
        pure
        returns (HttpMessages.Options memory options)
    {
        options.maxRequestHeaders = 1000;
        options.maxRequestHeaderLength = 1000;
        options.maxPathLength = 1000;
        return options;
    }

    constructor(WebApp _app) HttpServer(_app, customHttpMessagesOptions()) {}
}
```

### [`WebApp`](https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol) (`src/WebApp.sol:WebApp`)

Extend this contract to define routes in a custom web app. For example:

```solidity title="MyApp.sol" showLineNumbers
contract MyApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    function getGithub() external pure returns (HttpMessages.Response memory) {
        return redirect(302, "https://github.com/nathanhleung/fallback");
    }
}
```

If `debug` mode is enabled on [`WebApp`](https://github.com/nathanhleung/fallback/blob/main/src/WebApp.sol), the error pages will show the full request and response data.

#### Response Helper Functions

`WebApp` defines some response helper functions to make constructing responses easier:

- `text(string textString) returns (HttpMessages.Response)`
  - Creates a response with `Content-Type: text/plain`
- `json(string jsonString) returns (HttpMessages.Response)`
  - Creates a response with `Content-Type: application/json`
- `html(string htmlString) returns (HttpMessages.Response)`
  - Creates a response with `Content-Type: text/html`
- `redirect(uint16 statusCode, string location) returns (HttpMessages.Response)`
  - Creates a redirect response with the given status code to the given location
- `redirect(string location) returns (HttpMessages.Response)`
  - Creates a temporary redirect response (302) to the given location

#### Error Handlers

- `handleNotFound(HttpMessages.Request) returns (HttpMessages.Response)`
  - Override this function to customize the 404 page
- `handleBadRequest(HttpMessages.Request) returns (HttpMessages.Response)`
  - Override this function to customize the 400 page
- `handleError(HttpMessages.Request) returns (HttpMessages.Response)`
  - Override this function to customize the 500 page

> In `debug` mode, example error pages can be accessed at the paths `/__not_found` (404), `/__bad_request` (400), and `/__error` (500).

To return other HTTP error codes, set the `statusCode` member on the `HttpMessages.Response` struct and set the content manually.

## [`H`](https://github.com/nathanhleung/fallback/blob/main/src/html-dsl/H.sol) (`src/html-dsl/H.sol:H`)

A Solidity HTML DSL, inspired by [HyperScript](https://github.com/hyperhype/hyperscript) and [Pug](https://github.com/pugjs/pug). The basic building block of `H` is the function `H.h`, which has three variations:

- `h(string tagName) returns (string)`
  - Returns the tag without any children (e.g. `h("div") => "<div></div>"`)
- `h(string tagName, string childrenOrAttributes) returns (string)`
  - Returns the tag with the given children (or attributes if the tag is self-closing)
- `h(string tagName, string attributes, string children) returns (string)`
  - Returns the tag with the given attributes and children

The list of self-closing tags is taken from [the HTML spec](https://html.spec.whatwg.org/multipage/syntax.html#void-elements) and `H.h` handles self-closing behavior accordingly.

In addition to `H.h`, functions are present on the `H` contract for all standard HTML elements. Each standard HTML element has three functions, e.g. for `div`:

- `div() returns (string)`
  - Returns `h("div")`, i.e. `"<div></div>"`
- `div(string children) returns (string)`
  - Returns `h("div", children)`
- `div(string attributes, string children) returns (string)`
  - Returns `h("div", attributes, children)`

If the tag is self-closing, it does not have the third function above, and the second function creates the tag with attributes rather than children.

## Type Contracts

These contracts should be imported only to access the types defined on them; their actual code should be considered private implementation details.

- `src/http/HttpConstants.sol`: Import this contract to access the `HttpContants.Method` enum
- `src/http/HttpMessages.sol`: Import this contract to access the `HttpMessages.Options`, `HttpMessages.Request` and `HttpMessages.Response` structs

## Utility Libraries

These contracts are utility libraries that you are free to use but aren't core to fallback() itself.

- `src/strings/*.sol`: String casing, comparison, and concatenation utilities
- `src/integers/Integers.sol`: Integer utilities
