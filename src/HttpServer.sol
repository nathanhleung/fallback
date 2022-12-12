// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Http.sol";
import "./WebApp.sol";

/**
 * Public entrypoint. Takes in a `WebApp` and constructs a functional
 * Solidity HTTP server.
 */
contract HttpServer is HttpProxy, Ownable {
    constructor(WebApp _app) {
        app = _app;
        handler = new HttpHandler(_app);
        messages = new HttpMessages();
    }
}
