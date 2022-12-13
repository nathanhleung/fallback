// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./utils/H.sol";
import "./utils/HttpConstants.sol";
import "./utils/HttpMessages.sol";
import "forge-std/console.sol";

/**
 * Web app developers need to implement this contract, then pass it to
 * `HttpServer`'s constructor.
 *
 * To add more routes, add the path to the `routes` mapping
 * (under the appropriate HTTP method) with the name of the
 * function to run for the route and implement the function
 * Make sure the function has the signature
 * `functionName(string[],bytes)` and it returns
 * `(uint16,string[],string memory)`.
 */
abstract contract WebApp is Ownable {
    using Strings for uint16;
    HttpConstants c = new HttpConstants();
    bool public debug = false;

    // The handler for a given route is given by `routes[METHOD][path]`
    mapping(HttpConstants.Method => mapping(string => string)) public routes;
    mapping(HttpConstants.Method => mapping(string => string)) public test;

    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";

        // Internal routes, do not edit
        routes[HttpConstants.Method.GET]["/__not_found"] = "handleNotFound";
        routes[HttpConstants.Method.GET]["/__bad_request"] = "handleBadRequest";
        routes[HttpConstants.Method.GET]["/__error"] = "handleError";
    }

    function setDebug(bool _debug) external onlyOwner {
        debug = _debug;
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

    function handleNotFound(
        string[] memory requestHeaders,
        bytes memory requestContent
    )
        public
        returns (
            uint16 statusCode,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        return handleStatusCode(requestHeaders, requestContent, 404);
    }

    function handleBadRequest(
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
        return handleStatusCode(requestHeaders, requestContent, 400);
    }

    function handleError(
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
        return handleStatusCode(requestHeaders, requestContent, 500);
    }

    function handleStatusCode(
        string[] memory requestHeaders,
        bytes memory requestContent,
        uint16 statusCode
    )
        internal
        returns (
            uint16,
            string[] memory responseHeaders,
            string memory responseContent
        )
    {
        string memory statusCodeString = StringConcat.concat(
            statusCode.toString(),
            " ",
            c.STATUS_CODE_STRINGS(statusCode)
        );

        responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        responseContent = H.html(
            StringConcat.concat(
                H.head(H.title(statusCodeString)),
                H.body(
                    StringConcat.concat(
                        H.h1(statusCodeString),
                        H.p(debug ? string(requestContent) : ""),
                        H.hr(),
                        H.p(H.i("fallback() web server"))
                    )
                )
            )
        );

        return (statusCode, responseHeaders, responseContent);
    }

    // TODO(nathanhleung)
    // test this -- need to set a route in the route map
    // but have the actual function be nonexistent
    fallback() external {
        (string[] memory requestHeaders, bytes memory requestContent) = abi
            .decode(msg.data, (string[], bytes));

        handleNotFound(requestHeaders, requestContent);
        assembly {
            // https://ethereum.stackexchange.com/questions/131771/when-writing-assembly-to-which-memory-address-should-i-start-writing
            let freeMemoryPointer := mload(0x40)

            // Copy returndata into free memory
            returndatacopy(freeMemoryPointer, 0, returndatasize())

            // Return returndata
            return(freeMemoryPointer, returndatasize())
        }
    }
}
