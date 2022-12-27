// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "../html-dsl/H.sol";
import {StringConcat} from "../strings/StringConcat.sol";
import {WebApp} from "../WebApp.sol";
import {HttpHandler} from "./HttpHandler.sol";
import {HttpMessages} from "./HttpMessages.sol";

/**
 * Parses arbitrary HTTP requests sent as bytes in the `fallback`
 * function, then forwards parsed HTTP request data to `HttpHandler`.
 */
contract HttpProxy {
    using StringConcat for string;
    using Strings for uint256;

    event Response(bytes responseBytes);

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
                    app.debug()
                        ? StringConcat.concat(
                            "Panic(",
                            reason.toHexString(),
                            ")"
                        )
                        : ""
                );

                messages.buildResponse(response);
            }
        } catch Error(string memory reason) {
            HttpMessages.Request memory request;
            request.raw = requestBytes;
            HttpMessages.Response memory response = app.handleError(
                request,
                app.debug() ? StringConcat.concat("Error(", reason, ")") : ""
            );

            // return value is used by inline assembly below
            messages.buildResponse(response);
        } catch Panic(uint256 reason) {
            HttpMessages.Request memory request;
            request.raw = requestBytes;
            HttpMessages.Response memory response = app.handleBadRequest(
                request,
                app.debug()
                    ? StringConcat.concat("Panic(", reason.toHexString(), ")")
                    : ""
            );

            messages.buildResponse(response);
        }

        bytes32 responseTopic = bytes32(keccak256("Response(bytes)"));
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

            // Emit event
            log1(responseBytesPointer, responseBytesLength, responseTopic)

            // Don't return the ABI-encoded bytes array, just return
            // the actual bytes data itself
            return(responseBytesPointer, responseBytesLength)
        }
    }
}
