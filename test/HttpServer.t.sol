// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {HttpServer} from "../src/HttpServer.sol";
import {SimpleExampleServer} from "../src/example/SimpleExample.sol";

contract HttpServerTest is Test {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new SimpleExampleServer();
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
        assertEq(success, true);
        console.logString(responseString);
    }

    function testPostForm() public {
        bytes memory request = bytes(
            "POST /form HTTP/1.1\r\n"
            "\r\n"
            "random post data"
        );

        (bool success, bytes memory responseBytes) = address(httpServer).call(
            request
        );

        assertEq(success, true);
        string memory responseString = string(responseBytes);
        console.logString(responseString);
    }
}
