// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./utils/H.sol";
import "./utils/HttpConstants.sol";
import "./utils/HttpMessages.sol";
import "forge-std/console2.sol";

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

        // In debug mode, expose test error pages
        if (debug) {
            routes[HttpConstants.Method.GET]["/__not_found"] = "handleNotFound";
            routes[HttpConstants.Method.GET][
                "/__bad_request"
            ] = "handleBadRequest";
            routes[HttpConstants.Method.GET]["/__error"] = "handleError";
        }
    }

    function setDebug(bool _debug) external onlyOwner {
        debug = _debug;
    }

    function getIndex(HttpMessages.Request calldata request)
        external
        virtual
        returns (HttpMessages.Response memory);

    function handleNotFound(
        HttpMessages.Request memory request,
        string memory errorMessage
    ) public virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 404, errorMessage);
    }

    function handleBadRequest(
        HttpMessages.Request calldata request,
        string memory errorMessage
    ) external virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 400, errorMessage);
    }

    function handleError(
        HttpMessages.Request calldata request,
        string memory errorMessage
    ) external virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 500, errorMessage);
    }

    function handleStatusCode(
        HttpMessages.Request memory request,
        uint16 statusCode,
        string memory errorMessage
    ) internal virtual returns (HttpMessages.Response memory) {
        string memory statusCodeString = StringConcat.concat(
            statusCode.toString(),
            " ",
            c.STATUS_CODE_STRINGS(statusCode)
        );

        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        // Stack too deep
        string memory requestHeadersString = StringConcat.join(
            request.headers,
            "\r\n"
        );

        string memory requestBytesString;
        {
            requestBytesString = string(request.raw);
        }
        string memory requestContentString;
        {
            requestContentString = request.contentLength > 0
                ? H.pre(string(request.content))
                : "(empty)";
        }
        string memory debugString;
        {
            debugString = H.div(
                StringConcat.concat(
                    H.p(errorMessage),
                    H.h2("Raw Request"),
                    H.pre(requestBytesString),
                    H.h2("Parsed Request Headers"),
                    H.pre(requestHeadersString),
                    H.h2("Parsed Request Content"),
                    H.p(requestContentString)
                )
            );
        }

        string memory responseContent = H.html(
            StringConcat.concat(
                H.head(H.title(statusCodeString)),
                H.body(
                    StringConcat.concat(
                        H.h1(statusCodeString),
                        debug ? debugString : "",
                        H.hr(),
                        H.p(H.i("fallback() web server"))
                    )
                )
            )
        );

        HttpMessages.Response memory response;
        response.statusCode = statusCode;
        response.headers = responseHeaders;
        response.content = responseContent;
        return response;
    }

    // TODO(nathanhleung)
    // test this -- need to set a route in the route map
    // but have the actual function be nonexistent
    fallback() external {
        // Slice off function selector
        bytes calldata requestBytes = msg.data[4:];
        HttpMessages.Request memory request = abi.decode(
            requestBytes,
            (HttpMessages.Request)
        );
        HttpMessages.Response memory response = handleNotFound(request, "");
        bytes memory responseBytes = abi.encode(response);
        uint256 responseBytesLength = responseBytes.length;
        assembly {
            // Return returndata, skipping the first 32 bytes
            // (bytes memory setup)
            // TODO(nathanhleung) actually figure out why this works
            return(add(responseBytes, 32), add(responseBytesLength, 32))
        }
    }
}
