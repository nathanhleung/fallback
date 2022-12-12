// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./WebApp.sol";

contract ExampleApp is WebApp {
    constructor() {
        routes["/"] = "getIndex";
        routes["/debug"] = "getDebug";
        routes["/error"] = "getError";
        routes["/github"] = "getGithub";
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
    {}

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
    {}

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
    {}
}
