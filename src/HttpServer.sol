// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HttpHandler {
    function handleRoute(string calldata route)
        returns (uint8 statusCode, string memory responseContent)
    {
        // TODO(nathanhleung) Create Solidity HTML DSL?
        return (
            200,
            "<!DOCTYPE html>"
            "<html>"
            "<head><title>Hello World</title></head>"
            "<body><p>What hath god wrought?</p></body>"
            "</html>"
        );
    }
}

contract HttpResponseBuilder {
    function buildResponse(uint8 statusCode, string calldata responseContent)
        returns (bytes memory responseBytes)
    {
        string memory responseHeaders = string.concat(
            string.concat("HTTP/1.1", string(statusCode)),
            "OK\n"
        );
        responseHeaders = string.concat(
            responseHeaders,
            "OK\n"
            "Server: fallback()\n"
            "Content-Type: text/html; charset=utf-8\n"
        );
        responseHeaders = string.concat(
            responseHeaders,
            string.concat("Date: " + block.timestamp)
        );
        uint256 contentLength = bytes(responseContent).length;
        responseHeaders = string.concat(
            responseHeaders,
            string.concat("Content-Length: ", Strings.toString(contentLength))
        );

        string memory response = string.concat(
            string.concat(responseHeaders, "\n"),
            responseContent
        );

        return bytes(response);
    }
}

contract HttpProxy {
    HttpHandler private handler;
    HttpResponseBuilder private responseBuilder;

    constructor() {
        handler = new HttpHandler();
        responseBuilder = new HttpResponseBuilder();
    }

    fallback() external {
        bytes memory requestBytes = msg.data;
        // TODO(nathanhleung): parse route from request
        string memory route = "/";

        (uint8 statusCode, string memory responseContent) = handler.handleRoute(
            route
        );
        bytes memory responseBytes = responseBuilder.buildResponse(
            statusCode,
            responseContent
        );
        assembly {
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }
}

// Rename for public API
contract HttpServer is HttpProxy {

}
