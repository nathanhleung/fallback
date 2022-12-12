// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * Users need to implement this contract, then pass it to
 * `HttpServer`'s constructor.
 *
 * To add more routes, add the path to the `routes` mapping
 * with the name of the function to run for the route and
 * implement the function. Make sure the function has the
 * signature `functionName(string[],bytes)` and it returns
 * `(uint16,string[],string memory)`.
 */
abstract contract WebApp {
    mapping(string => string) public routes;

    constructor() {
        routes["/"] = "getIndex";
    }

    function getIndex(
        string[] memory requestHeaders,
        bytes memory requestContent
    )
        external
        virtual
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {}
}
