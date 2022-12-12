// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/HttpServer.sol";
import "../src/ExampleApp.sol";

contract HttpServerTest is Test {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new HttpServer(new ExampleApp());
    }

    function testRequest() public {
        bytes memory request = bytes(
            "GET / HTTP/1.1\n"
            "Host: 127.0.0.1\n"
            "Accept-Language: en-US,en\n"
        );

        (bool success, bytes memory responseBytes) = address(httpServer).call(
            request
        );
        string memory responseString = string(responseBytes);
        console.logBool(success);
        console.logString(responseString);
    }
}
