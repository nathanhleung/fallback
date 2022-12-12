// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/HttpServer.sol";
import "../src/ExampleApp.sol";

contract HttpServerTest is Script {
    HttpServer public httpServer;

    function setUp() public {
        httpServer = new HttpServer(new ExampleApp());
    }

    function run() public {
        bytes memory getIndexRequest = bytes(
            "GET / HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );

        (bool getIndexSuccess, bytes memory getIndexResponseBytes) = address(
            httpServer
        ).call(getIndexRequest);
        console.log(string(getIndexResponseBytes));

        bytes memory getGithubRequest = bytes(
            "GET /github HTTP/1.1\r\n"
            "Host: 127.0.0.1\r\n"
            "Accept-Language: en-US,en\r\n"
        );

        (bool getGithubSuccess, bytes memory getGithubResponseBytes) = address(
            httpServer
        ).call(getGithubRequest);
        console.log(string(getGithubResponseBytes));
    }
}
