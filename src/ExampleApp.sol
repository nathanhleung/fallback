// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./utils/HttpMessages.sol";
import "./WebApp.sol";

contract ExampleApp is WebApp {
    constructor() {
        routes[HttpMessages.Method.GET]["/"] = "getIndex";
        routes[HttpMessages.Method.GET]["/debug"] = "getDebug";
        routes[HttpMessages.Method.GET]["/error"] = "getError";
        routes[HttpMessages.Method.GET]["/github"] = "getGithub";
        test[HttpMessages.Method.GET]["string"] = "hey";
    }

    function getIndex(
        string[] memory requestHeaders,
        bytes memory requestContent
    )
        external
        override
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        statusCode = 200;

        responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        responseContent = "<!DOCTYPE html>"
        "<html>"
        "<head><title>Hello World</title></head>"
        "<body><p>What hath god wrought?</p></body>"
        "</html>";

        // TODO(nathanhleung) Create Solidity HTML DSL?
        return (statusCode, responseHeaders, responseContent);
    }

    function getDebug(
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
        // TODO(nathanhleung): show smart contract internals
    }

    function getError(
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
        // TODO(nathanhleung): call a function that will revert
    }

    function getGithub(
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
        responseHeaders = new string[](1);
        responseHeaders[
            0
        ] = "Location: https://github.com/nathanhleung/fallback";

        return (302, responseHeaders, "");
    }

    fallback() external {
        // TODO(nathanhleung) return 404
    }
}
