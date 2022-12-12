// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./StringConcat.sol";
import "./WebApp.sol";

/**
 * Utility function to build a raw HTTP response given a status
 * code, headers, and response content.
 */
library HttpResponseBuilder {
    using StringConcat for string;
    using Strings for uint16;
    using Strings for uint256;

    function buildResponse(
        uint16 statusCode,
        string[] calldata responseHeaders,
        string calldata responseContent
    ) external returns (bytes memory responseBytes) {
        string memory responseHeadersString = "";
        responseHeadersString = responseHeadersString.concat(
            "HTTP/1.1 ",
            statusCode.toString(),
            " OK\n"
            "Server: fallback()\n"
        );

        for (uint8 i = 0; i < responseHeaders.length; i += 1) {
            responseHeadersString = responseHeadersString.concat(
                responseHeaders[i],
                "\n"
            );
        }

        responseBytes = bytes(
            responseHeadersString.concat(
                "Date: ",
                block.timestamp.toString(),
                "\n"
                "Content-Length: ",
                bytes(responseContent).length.toString(),
                "\n\n",
                responseContent
            )
        );

        return responseBytes;
    }
}

/**
 * Maps HTTP requests to the correct routes in the `WebApp`,
 * returns HTTP response data.
 */
contract HttpHandler {
    WebApp app;

    constructor(WebApp webApp) {
        app = webApp;
    }

    function handleRoute(
        string calldata route,
        string[] memory requestHeaders,
        bytes memory requestContent
    )
        external
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        (bool success, bytes memory data) = address(app).call(
            abi.encodeWithSignature(
                // All routes have a signature of `routeName(string[],bytes)`
                string.concat(app.routes(route), "(string[],bytes)"),
                responseHeaders,
                responseContent
            )
        );

        if (!success) {
            statusCode = 500;

            responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            // TODO(nathanhleung) Create Solidity HTML DSL?
            responseContent = "<!DOCTYPE html>"
            "<html>"
            "<head><title>500 Server Error</title></head>"
            "<body><p>Internal Server Error</p></body>"
            "</html>";
        } else {
            statusCode = 200;

            responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            responseContent = "<!DOCTYPE html>"
            "<html>"
            "<head><title>Hello World</title></head>"
            "<body><p>What hath god wrought?</p></body>"
            "</html>";
        }

        return (statusCode, responseHeaders, responseContent);
    }
}

/**
 * Parses arbitrary HTTP requests sent as bytes via the fallback
 * function, forwards parsed HTTP request data to `HttpHandler`.
 */
contract HttpProxy {
    /**
     * Handles HTTP requests. Set by consumer in `HttpServer`.
     */
    HttpHandler internal handler;

    /**
     * Since this contract has no functions besides `fallback()`,
     * all calls will be sent here. So if a user sends HTTP bytes
     * to this contract, we'll be able to parse them in here.
     */
    fallback() external {
        bytes memory requestBytes = msg.data;
        // TODO(nathanhleung): parse route from request
        requestBytes;

        string memory route = "/";
        string[] memory requestHeaders = new string[](1);
        requestHeaders[0] = "Host: localhost";
        requestHeaders[0] = "Content-Length: 0";
        bytes memory requestContent = bytes("");

        (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        ) = handler.handleRoute(route, requestHeaders, requestContent);

        // return value is used by inline assembly below
        HttpResponseBuilder.buildResponse(
            statusCode,
            responseHeaders,
            responseContent
        );

        assembly {
            // https://ethereum.stackexchange.com/questions/131771/when-writing-assembly-to-which-memory-address-should-i-start-writing
            let freeMemoryPointer := mload(0x40)

            // Copy returndata into free memory
            returndatacopy(freeMemoryPointer, 0, returndatasize())

            // `responseBuilder.buildResponse` returns `bytes`, so
            // `returndata` will by a dynamic byte array

            // https://ethereum.stackexchange.com/questions/60563/why-is-the-returndata-of-a-function-returning-bytes-formatted-in-a-weird-way
            // The first 32 bytes of the returned data will be the offset
            // to the start of the returned data. The first 32 bytes of the
            // returned data will be the length of the data, followed by the
            // bytes. So the total offset is `mload(freeMemoryPointer)` + 32
            // to skip the length portion.
            let responseBytesOffset := add(mload(freeMemoryPointer), 32)
            let responseBytesPointer := add(
                freeMemoryPointer,
                responseBytesOffset
            )
            // The actual size of the bytes only is the total size of the
            // returned data minus the offset at the beginning we skip
            let responseBytesLength := sub(
                returndatasize(),
                responseBytesOffset
            )

            // Don't return the ABI-encoded bytes array, just return
            // the actual bytes data itself
            return(responseBytesPointer, responseBytesLength)
        }
    }
}
