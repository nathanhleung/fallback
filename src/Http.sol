// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/StringConcat.sol";
import "./WebApp.sol";

/**
 * Maps HTTP requests to the correct routes in the `WebApp`,
 * and returns HTTP response data.
 */
contract HttpHandler {
    using StringConcat for string;

    WebApp app;

    constructor(WebApp webApp) {
        app = webApp;
    }

    /**
     * Calls the correct function on the web app contract based
     * on the route passed in.
     */
    function handleRoute(
        HttpMessages.Method method,
        string memory path,
        string[] memory requestHeaders,
        bytes memory requestContent,
        bool debug
    )
        external
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        app.getIndex(requestHeaders, requestContent);
        (bool success, bytes memory data) = address(app).call(
            abi.encodeWithSignature(
                // All routes have a signature of `routeName(string[],bytes)`
                StringConcat.concat(
                    app.routes(method, path),
                    "(string[],bytes)"
                ),
                responseHeaders,
                responseContent
            )
        );

        if (!success) {
            statusCode = 500;

            responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            // Grab revert reason
            // https://ethereum.stackexchange.com/a/86983
            bytes memory revertReason;
            assembly {
                let freeMemoryPointer := mload(0x40)
                returndatacopy(freeMemoryPointer, 0, returndatasize())
                revertReason := mload(freeMemoryPointer)
            }

            // TODO(nathanhleung) Create Solidity HTML DSL?
            responseContent = "";
            responseContent = responseContent.concat(
                "<!DOCTYPE html>"
                "<html>"
                "<head><title>500 Server Error</title></head>"
                "<body>"
                "<h1>500 Internal Server Error</h1>",
                debug
                    ? StringConcat.concat("<p>", string(revertReason), "</p>")
                    : "",
                "<hr>"
                "<p><i>fallback() web server</i></p>"
                "</body>"
                "</html>"
            );
        } else {
            // TODO(nathanhleung): parse bytes memory data
            // returned data - should have all this

            statusCode = 200;
            responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            responseContent = "<!DOCTYPE html>"
            "<html>"
            "<head><title>fallback()</title></head>"
            "<body><h1>fallback() web server<h1>"
            "<p>default response</p></body>"
            "</html>";
        }

        return (statusCode, responseHeaders, responseContent);
    }

    /**
     * Handles a route, sets `debug` to `false` (i.e. this effectively
     * makes `false` the default value of the `debug` parameter).
     */
    function handleRoute(
        HttpMessages.Method method,
        string calldata path,
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
        return
            this.handleRoute(
                method,
                path,
                requestHeaders,
                requestContent,
                false
            );
    }
}

/**
 * Parses arbitrary HTTP requests sent as bytes in the `fallback`
 * function, then forwards parsed HTTP request data to `HttpHandler`.
 */
contract HttpProxy {
    using StringConcat for string;
    using Strings for uint256;

    /**
     * Handles HTTP requests. Set in constructor of `HttpServer`.
     */
    HttpHandler internal handler;

    /**
     * Utilities for building and parsing HTTP messages. Set in
     * constructor of `HttpServer`.
     */
    HttpMessages internal messages;

    /**
     * Whether to turn debug mode on or not (show errors on
     * error pages). Set by `HttpServer`.
     */
    bool internal debug;

    /**
     * Since this contract has no functions besides `fallback()`,
     * all calls will be sent here. So if a user sends HTTP bytes
     * to this contract, we'll be able to parse them in here.
     */
    fallback() external {
        bytes memory requestBytes = msg.data;

        // If we hit an error in parsing, we return 400
        try messages.parseRequest(requestBytes) returns (
            HttpMessages.Method method,
            string memory path,
            string[] memory requestHeaders,
            bytes memory requestContent
        ) {
            (
                uint16 statusCode,
                string[] memory responseHeaders,
                string memory responseContent
            ) = handler.handleRoute(
                    method,
                    path,
                    requestHeaders,
                    requestContent
                );

            // return value is used by inline assembly below
            messages.buildResponse(
                statusCode,
                responseHeaders,
                responseContent
            );
        } catch Error(string memory reason) {
            uint16 statusCode = 400;

            string[] memory responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            // TODO(nathanhleung) Create Solidity HTML DSL?
            string memory responseContent = "";
            responseContent = responseContent.concat(
                "<!DOCTYPE html>"
                "<html>"
                "<head><title>400 Bad Request</title></head>"
                "<body>"
                "<h1>400 Bad Request</h1>",
                (debug ? StringConcat.concat("<p>", reason, "</p>") : ""),
                "<hr>"
                "<p><i>fallback() web server</i></p>"
                "</body>"
                "</html>"
            );

            messages.buildResponse(400, responseHeaders, responseContent);
        } catch Panic(uint256 reason) {
            uint16 statusCode = 400;

            string[] memory responseHeaders = new string[](1);
            responseHeaders[0] = "Content-Type: text/html";

            // TODO(nathanhleung) Create Solidity HTML DSL?
            string memory responseContent = "";
            responseContent = responseContent.concat(
                "<!DOCTYPE html>"
                "<html>"
                "<head><title>400 Bad Request</title></head>"
                "<body>"
                "<h1>400 Bad Request</h1>",
                (
                    debug
                        ? StringConcat.concat(
                            "<p>",
                            "Panic encountered while parsing HTTP request. Code: ",
                            reason.toHexString(),
                            "</p>"
                        )
                        : ""
                ),
                "<hr>"
                "<p><i>fallback() web server</i></p>"
                "</body>"
                "</html>"
            );

            messages.buildResponse(400, responseHeaders, responseContent);
        }

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
