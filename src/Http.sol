// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/H.sol";
import "./utils/HttpConstants.sol";
import "./utils/StringConcat.sol";
import "./WebApp.sol";
import "forge-std/console.sol";

/**
 * Maps HTTP requests to the correct routes in the `WebApp`,
 * and returns HTTP response data.
 */
contract HttpHandler {
    using StringConcat for string;

    WebApp public app;

    constructor(WebApp webApp) {
        app = webApp;
    }

    /**
     * Calls the correct function on the web app contract based
     * on the route passed in.
     */
    function handleRoute(
        HttpConstants.Method method,
        string memory path,
        string[] memory requestHeaders,
        bytes calldata requestContent
    )
        external
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        string memory routeHandlerName = app.routes(method, path);

        // If route is unset, return 404
        if (bytes(routeHandlerName).length == 0) {
            (
                uint16 _statusCode,
                string[] memory _responseHeaders,
                string memory _responseContent
            ) = app.handleNotFound(requestHeaders, requestContent);

            return (_statusCode, _responseHeaders, _responseContent);
        }

        (bool success, bytes memory data) = address(app).call(
            abi.encodeWithSignature(
                // All routes have a signature of `routeName(string[],bytes)`
                StringConcat.concat(
                    app.routes(method, path),
                    "(string[],bytes)"
                ),
                requestHeaders,
                requestContent
            )
        );

        // If unsuccessful call, return 500
        if (!success) {
            assembly {
                // Slice the sighash
                // https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th/83577#83577
                data := add(data, 0x04)
            }
            string memory revertReason = abi.decode(data, (string));

            (
                uint16 _statusCode,
                string[] memory _responseHeaders,
                string memory _responseContent
            ) = app.handleError(requestHeaders, bytes(revertReason));

            return (_statusCode, _responseHeaders, _responseContent);
        }

        (
            uint16 _statusCode,
            string[] memory _responseHeaders,
            string memory _responseContent
        ) = abi.decode(data, (uint16, string[], string));

        return (_statusCode, _responseHeaders, _responseContent);
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
     * Set in constructor of `HttpServer`.
     */
    WebApp internal app;

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
     * Since this contract has no functions besides `fallback()`,
     * all calls will be sent here. So if a user sends HTTP bytes
     * to this contract, we'll be able to parse them in here.
     */
    fallback() external {
        bytes memory requestBytes = msg.data;

        // If we hit an error in parsing, we return 400
        try messages.parseRequest(requestBytes) returns (
            HttpConstants.Method method,
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
            string[] memory requestHeaders = new string[](2);
            requestHeaders[0] = StringConcat.concat(
                "Content-Type",
                "text/plain"
            );
            requestHeaders[1] = StringConcat.concat(
                "Content-Length",
                bytes(reason).length.toString()
            );
            (
                uint16 statusCode,
                string[] memory responseHeaders,
                string memory responseContent
            ) = handler.handleRoute(
                    HttpConstants.Method.GET,
                    "/__bad_request",
                    requestHeaders,
                    bytes(reason)
                );

            // return value is used by inline assembly below
            messages.buildResponse(
                statusCode,
                responseHeaders,
                responseContent
            );
        } catch Panic(uint256 reason) {
            string[] memory requestHeaders = new string[](1);
            requestHeaders[0] = StringConcat.concat(
                "Content-Length",
                // uint256 is 32 bytes
                "32"
            );
            (
                uint16 statusCode,
                string[] memory responseHeaders,
                string memory responseContent
            ) = handler.handleRoute(
                    HttpConstants.Method.GET,
                    "/__bad_request",
                    requestHeaders,
                    bytes(
                        StringConcat.concat(
                            "Solidity panicked while parsing HTTP request. Code: ",
                            reason.toHexString()
                        )
                    )
                );

            messages.buildResponse(
                statusCode,
                responseHeaders,
                responseContent
            );
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
