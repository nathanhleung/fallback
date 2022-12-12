// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Http.sol";
import "./WebApp.sol";

/**
 * Public entrypoint. Takes in a `WebApp` and constructs a functional
 * Solidity HTTP server.
 */
contract HttpServer is HttpProxy {
    constructor(WebApp webApp) {
        handler = new HttpHandler(webApp);
    }
}
