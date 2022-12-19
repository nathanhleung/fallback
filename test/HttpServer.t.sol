// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/HttpServer.sol";
import "../src/example/Example.sol";

contract HttpServerTest is Test {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new ExampleServer();
    }

    // TODO(nathanhleung) write tests
    function testRequest() public {
        bytes memory request = bytes(
            "GET / HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );

        (bool success, bytes memory responseBytes) = address(httpServer).call(
            request
        );
        string memory responseString = string(responseBytes);
        console.logBool(success);
        console.logString(responseString);
    }
}
