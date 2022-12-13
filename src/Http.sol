// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./utils/H.sol";
import "./utils/HttpConstants.sol";
import "./utils/StringConcat.sol";
import "./WebApp.sol";

/**
 * Maps HTTP requests to the correct routes in the `WebApp`,
 * and returns HTTP response data.
 */
contract HttpHandler {
    using StringConcat for string;
    using Strings for uint256;

    WebApp public app;

    constructor(WebApp webApp) {
        app = webApp;
    }

    /**
     * Calls the correct function on the web app contract based
     * on the route passed in.
     */
    function handleRoute(HttpMessages.Request memory request)
        external
        returns (HttpMessages.Response memory)
    {
        string memory routeHandlerName = app.routes(
            request.method,
            request.path
        );

        // If route is unset in `routes` mapping, return 404
        if (bytes(routeHandlerName).length == 0) {
            return
                app.handleNotFound(
                    request,
                    request.path.concat(" not found on this server")
                );
        }

        // All routes should take a `Request` struct.
        // But we should also handle omitted params in case someone
        // forgets.
        string[] memory possibleSignatures = new string[](2);
        possibleSignatures[0] = "((uint8,string,string[],uint256,bytes,bytes))";
        possibleSignatures[1] = "()";

        for (uint256 i = 0; i < possibleSignatures.length; i += 1) {
            HttpMessages.Response memory response = safeCallApp(
                request,
                routeHandlerName.concat(possibleSignatures[i])
            );

            // If we found a valid route, return the successful
            // response.
            if (response.statusCode != 404) {
                return response;
            }

            // If we're on the last signature AND it's a 404
            // return the 404 page with a message saying we
            // didn't find the route.
            if (i + 1 == possibleSignatures.length) {
                return
                    app.handleNotFound(
                        request,
                        StringConcat.concat(
                            request.path,
                            " not found on this server"
                        )
                    );
            }
        }
    }

    /**
     * Calls the function on the app contract with the given
     * signature, passing the params.
     */
    function safeCallApp(
        HttpMessages.Request memory request,
        string memory signature
    ) private returns (HttpMessages.Response memory) {
        (bool success, bytes memory data) = address(app).call(
            abi.encodeWithSignature(signature, request)
        );

        // If unsuccessful call, return 500
        if (!success) {
            assembly {
                // Slice the sighash
                // https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th/83577#83577
                data := add(data, 0x04)
            }
            string memory revertReason = abi.decode(data, (string));

            return
                app.handleError(
                    request,
                    StringConcat.concat("Error(", revertReason, ")")
                );
        }

        return abi.decode(data, (HttpMessages.Response));
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
            HttpMessages.Request memory request
        ) {
            try handler.handleRoute(request) returns (
                HttpMessages.Response memory response
            ) {
                // return value is used by inline assembly below
                messages.buildResponse(response);
                // `handleRoute` handles reverts internally,
                // but it can still `Panic`. `try` only works
                // with external function calls, so we check here.
            } catch Panic(uint256 reason) {
                HttpMessages.Response memory response = app.handleError(
                    request,
                    StringConcat.concat("Panic(", reason.toString(), ")")
                );

                messages.buildResponse(response);
            }
        } catch Error(string memory reason) {
            HttpMessages.Request memory request;
            request.raw = requestBytes;
            HttpMessages.Response memory response = app.handleError(
                request,
                StringConcat.concat("Error(", reason, ")")
            );

            // return value is used by inline assembly below
            messages.buildResponse(response);
        } catch Panic(uint256 reason) {
            HttpMessages.Request memory request;
            request.raw = requestBytes;
            HttpMessages.Response memory response = app.handleBadRequest(
                request,
                StringConcat.concat("Panic(", reason.toString(), ")")
            );

            messages.buildResponse(response);
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
