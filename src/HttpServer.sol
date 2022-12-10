// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract HttpHandler {
    function handleRoute(string calldata route)
        external
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
        external
        returns (bytes memory responseBytes)
    {
        string memory responseHeaders = string.concat(
            string.concat("HTTP/1.1 ", Strings.toString(statusCode)),
            " OK\n"
        );
        responseHeaders = string.concat(
            responseHeaders,
            "OK\n"
            "Server: fallback()\n"
            "Content-Type: text/html; charset=utf-8\n"
        );
        responseHeaders = string.concat(
            string.concat(
                responseHeaders,
                string.concat("Date: ", Strings.toString(block.timestamp))
            ),
            "\n"
        );
        uint256 contentLength = bytes(responseContent).length;
        responseHeaders = string.concat(
            responseHeaders,
            string.concat("Content-Length: ", Strings.toString(contentLength))
        );

        string memory response = string.concat(
            string.concat(responseHeaders, "\n\n"),
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
        requestBytes;
        string memory route = "/";

        (uint8 statusCode, string memory responseContent) = handler.handleRoute(
            route
        );

        // returndata is returned by inline assembly below
        responseBuilder.buildResponse(statusCode, responseContent);
        assembly {
            returndatacopy(0, 0, returndatasize())
            // Get start of dynamic array
            let response_start := add(mload(0), 32)
            // Don't return the ABI encoding, just return
            // the actual response string data itself
            return(response_start, sub(returndatasize(), 64))
        }
    }
}

// Rename for public API
contract HttpServer is HttpProxy {

}
