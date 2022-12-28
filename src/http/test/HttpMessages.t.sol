// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StringCompare} from "../../strings/StringCompare.sol";
import {HttpConstants} from "../HttpConstants.sol";
import {HttpMessages} from "../HttpMessages.sol";

contract HttpMessagesTest is Test {
    HttpMessages public httpMessages;

    function setUp() public {
        HttpMessages.Options memory options;
        options.maxRequestHeaders = 4000;
        options.maxRequestHeaderLength = 4000;
        options.maxPathLength = 4000;
        httpMessages = new HttpMessages(options);
    }

    function testParseShortGetIndexRequest() public {
        bytes memory requestBytes = bytes("GET / HTTP/1.1");

        HttpMessages.Request memory request = httpMessages.parseRequest(
            requestBytes
        );
        assertEq(request.method == HttpConstants.Method.GET, true);
        assertEq(StringCompare.equals(request.path, "/"), true);
    }

    function testParseFullGetIndexRequest() public {
        bytes memory requestBytes = bytes(
            "GET / HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );
        HttpMessages.Request memory request = httpMessages.parseRequest(
            requestBytes
        );
        assertEq(request.method == HttpConstants.Method.GET, true);
        assertEq(StringCompare.equals(request.path, "/"), true);
        assertEq(request.headers.length == 2, true);
        assertEq(request.content.length == 0, true);
    }

    function testParseShortPostRequest() public {
        bytes memory requestBytes = bytes(
            "POST /form HTTP/1.1\r\n"
            "Content-Length: 10\r\n"
            "\r\n"
            "random post data"
        );

        HttpMessages.Request memory request = httpMessages.parseRequest(
            requestBytes
        );
        assertEq(request.method == HttpConstants.Method.POST, true);
        assertEq(StringCompare.equals(request.path, "/form"), true);
        assertEq(request.headers.length == 1, true);
        // Short `Content-Length` header
        assertEq(request.content.length == 10, true);
        assertEq(
            StringCompare.equals(string(request.content), "random pos"),
            true
        );
    }

    function testParseFullPostRequest() public {
        bytes memory requestBytes = bytes(
            "POST /form HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
            "Content-Length: 27\r\n"
            "\r\n"
            "name=nate&favorite_number=2"
        );

        HttpMessages.Request memory request = httpMessages.parseRequest(
            requestBytes
        );
        assertEq(request.method == HttpConstants.Method.POST, true);
        assertEq(StringCompare.equals(request.path, "/form"), true);
        assertEq(request.headers.length == 3, true);
        // Short content length
        assertEq(request.content.length == 27, true);
        assertEq(
            StringCompare.equals(
                string(request.content),
                "name=nate&favorite_number=2"
            ),
            true
        );
    }
}
