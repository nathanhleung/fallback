// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Http.sol";
import "./WebApp.sol";

/**
 * Takes in a `WebApp` and server options constructs a functional
 * Solidity HTTP server.
 */
contract HttpServer is HttpProxy, Ownable {
    constructor(WebApp _app, HttpMessages.Options memory messagesOptions) {
        app = _app;
        handler = new HttpHandler(_app);
        messages = new HttpMessages(messagesOptions);
    }
}

/**
 * Takes in a `WebApp` and constructs a functional
 * Solidity HTTP server, setting reasonable default
 * `HttpServer` options.
 */
contract DefaultServer is HttpServer {
    function defaultHttpMessagesOptions()
        internal
        pure
        returns (HttpMessages.Options memory options)
    {
        options.maxRequestHeaders = 4000;
        options.maxRequestHeaderLength = 4000;
        // 4,000 characters for the path seems like a reasonable
        // assumption based on this SO answer.
        // https://stackoverflow.com/questions/1289585/what-is-apaches-maximum-url-length
        options.maxPathLength = 4000;
        return options;
    }

    constructor(WebApp _app) HttpServer(_app, defaultHttpMessagesOptions()) {}
}
