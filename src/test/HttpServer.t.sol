// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SimpleExampleServer} from "../example/SimpleExample.sol";
import {HttpServer} from "../HttpServer.sol";
import {StringCompare} from "../strings/StringCompare.sol";

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
        assertEq(success, true);

        string memory responseString = string(responseBytes);
        assertEq(
            StringCompare.startsWith(responseString, "HTTP/1.1 200 OK"),
            true
        );
        assertEq(
            StringCompare.contains(responseString, "Content-Type: text/html"),
            true
        );
        assertEq(
            StringCompare.contains(responseString, "<!DOCTYPE html>"),
            true
        );
        assertEq(
            StringCompare.contains(
                responseString,
                "<h1>fallback() web framework</h1>"
            ),
            true
        );
    }

    function testPostForm() public {
        bytes memory request = bytes(
            "POST /form HTTP/1.1\r\n"
            "Content-Length: 10"
            "\r\n"
            "random post data"
        );

        (bool success, bytes memory responseBytes) = address(httpServer).call(
            request
        );

        assertEq(success, true);

        string memory responseString = string(responseBytes);
        assertEq(
            StringCompare.startsWith(responseString, "HTTP/1.1 200 OK"),
            true
        );
        // First 10 characters, since Content-Length was 10
        assertEq(StringCompare.contains(responseString, "random pos"), true);
        assertEq(StringCompare.contains(responseString, "random post"), false);
    }
}
