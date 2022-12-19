// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HttpServer.sol";
import "../src/example/Example.sol";

contract HttpServerTest is Script {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new ExampleServer();
    }

    function run() public {
        bytes memory getIndexRequest = bytes(
            "GET / HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );

        (, bytes memory getIndexResponseBytes) = address(httpServer).call(
            getIndexRequest
        );
        console.log(string(getIndexResponseBytes));

        // bytes memory getGithubRequest = bytes(
        //     "GET /github HTTP/1.1\r\n"
        //     "Host: 127.0.0.1\r\n"
        //     "Accept-Language: en-US,en\r\n"
        // );

        // (, bytes memory getGithubResponseBytes) = address(httpServer).call(
        //     getGithubRequest
        // );
        // console.log(string(getGithubResponseBytes));

        // bytes memory getNotFoundRequest = bytes(
        //     "GET /nonexistent HTTP/1.1\r\n"
        //     "Host: 127.0.0.1\r\n"
        //     "Accept-Language: en-US,en\r\n"
        // );

        // (, bytes memory getNotFoundResponseBytes) = address(httpServer).call(
        //     getNotFoundRequest
        // );
        // console.log(string(getNotFoundResponseBytes));

        // bytes memory postFormRequest = bytes(
        //     "POST /form HTTP/1.1\r\n"
        //     "Host: 127.0.0.1\r\n"
        //     "Accept-Language: en-US,en\r\n"
        //     "Content-Length: 27\r\n"
        //     "\r\n"
        //     "name=nate&favorite_number=2"
        // );

        // (, bytes memory postFormResponseBytes) = address(httpServer).call(
        //     postFormRequest
        // );
        // console.log(string(postFormResponseBytes));

        // bytes memory getErrorRequest = bytes(
        //     "GET /error HTTP/1.1\r\n"
        //     "Host: 127.0.0.1\r\n"
        //     "Accept-Language: en-US,en\r\n"
        // );

        // (, bytes memory getErrorResponseBytes) = address(httpServer).call(
        //     getErrorRequest
        // );
        // console.log(string(getErrorResponseBytes));

        bytes memory getJsonRequest = bytes(
            "GET /json HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );

        (, bytes memory getJsonResponseBytes) = address(httpServer).call(
            getJsonRequest
        );
        console.log(string(getJsonResponseBytes));
    }
}
