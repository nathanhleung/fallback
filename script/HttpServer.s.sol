// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HttpServer.sol";

contract HttpServerTest is Script {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new HttpServer();
    }

    function run() public {
        bytes memory request = bytes(
            "GET / HTTP/1.1\n"
            "Host: 127.0.0.1\n"
            "Accept-Language: en-US,en\n"
        );

        (bool success, bytes memory responseBytes) = address(httpServer).call(
            request
        );
        console.logBytes(responseBytes);
        console.logString(string(responseBytes));
    }
}
