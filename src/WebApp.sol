// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "./html-dsl/H.sol";
import {HttpConstants} from "./http/HttpConstants.sol";
import {HttpMessages} from "./http/HttpMessages.sol";
import {StringConcat} from "./strings/StringConcat.sol";

/**
 * @title Web App, a base contract to create Solidity apps with
 * @author nathanhleung
 * @notice An abstract contract that can be extended to create
 *     arbitrary web apps.
 * @dev To create a new fallback() web app, first extend this contract,
 *     then pass it to `HttpServer`'s constructor.
 *
 *     To add more routes, add the path to the `routes` mapping
 *     (under the appropriate HTTP method) with the name of the
 *     function to run for the route and implement the function
 *     Make sure the function has the signature
 *     `functionName(HttpMessages.Request)` and it returns
 *     `(HttpMessages.Response)`.
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

    /**
     * @dev Sets whether the web app is operating in `debug` mode or not.
     *     In `debug` mode, error pages will show more details (e.g.
     *     the parsed request and response).
     * @param _debug The new debug mode value.
     */
    function setDebug(bool _debug) external onlyOwner {
        debug = _debug;
    }

    /**
     * @dev Creates an HTTP JSON response with the correct
     *     JSON `Content-Type` header set.
     */
    function json(string memory jsonString)
        internal
        pure
        returns (HttpMessages.Response memory response)
    {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: application/json";

        response.headers = responseHeaders;
        response.content = jsonString;
        return response;
    }

    /**
     * @dev Creates an HTTP HTML response with the correct
     *     HTML `Content-Type` header set.
     */
    function html(string memory htmlString)
        internal
        pure
        returns (HttpMessages.Response memory response)
    {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        response.headers = responseHeaders;
        response.content = htmlString;
        return response;
    }

    function redirect(uint16 statusCode, string memory location)
        internal
        pure
        returns (HttpMessages.Response memory response)
    {
        require(
            statusCode == 301 || statusCode == 302,
            "Redirect status code must be 301 or 302"
        );

        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = StringConcat.concat("Location: ", location);

        response.statusCode = statusCode;
        response.headers = responseHeaders;
        return response;
    }

    /**
     * @dev Default index route.
     */
    function getIndex(HttpMessages.Request calldata request)
        external
        virtual
        returns (HttpMessages.Response memory);

    /**
     * @dev Default 404 Not Found handler
     */
    function handleNotFound(
        HttpMessages.Request memory request,
        string memory errorMessage
    ) public virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 404, errorMessage);
    }

    /**
     * @dev Default 400 Bad Request handler
     */
    function handleBadRequest(
        HttpMessages.Request calldata request,
        string memory errorMessage
    ) external virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 400, errorMessage);
    }

    /**
     * @dev Default 500 Internal Server Error handler
     */
    function handleError(
        HttpMessages.Request calldata request,
        string memory errorMessage
    ) external virtual returns (HttpMessages.Response memory) {
        return handleStatusCode(request, 500, errorMessage);
    }

    /**
     * @dev Default handler for arbitrary status codes, used by
     * default `handleNotFound`, `handleBadRequest`, and
     * `handleError`.
     */
    function handleStatusCode(
        HttpMessages.Request memory request,
        uint16 statusCode,
        string memory errorMessage
    ) private view returns (HttpMessages.Response memory) {
        string memory statusCodeString = StringConcat.concat(
            statusCode.toString(),
            " ",
            c.STATUS_CODE_STRINGS(statusCode)
        );

        string memory requestHeadersString = StringConcat.join(
            request.headers,
            "\r\n"
        );

        string memory requestBytesString = string(request.raw);
        string memory requestContentString = request.contentLength > 0
            ? H.pre(string(request.content))
            : "(empty)";

        string memory debugString = H.div(
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

        string memory responseContent = H.html(
            StringConcat.concat(
                H.head(H.title(statusCodeString)),
                H.body(
                    StringConcat.concat(
                        H.h1(statusCodeString),
                        debug ? debugString : "",
                        H.hr(),
                        H.p(H.i("fallback() web framework"))
                    )
                )
            )
        );

        HttpMessages.Response memory response = html(responseContent);
        response.statusCode = statusCode;
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
