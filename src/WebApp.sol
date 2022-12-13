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
        console.log("in handle statuscode");

        string memory statusCodeString = StringConcat.concat(
            statusCode.toString(),
            " ",
            c.STATUS_CODE_STRINGS(statusCode)
        );

        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        // Stack too deep
        string memory requestHeadersString;
        {
            requestHeadersString = StringConcat.join(request.headers, "\r\n");
        }

        console.log("checkpoint");

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

        console.log("checkpoint 2");

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

        console.log("checkpoint 3");

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
        HttpMessages.Request memory request;
        // assembly {
        //     // Slice the sighash
        //     // https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th/83577#83577
        //     request := add(request, 0x04)
        // }

        // console.log("in fallback");
        // console.logBytes(msg.data);

        // console.logBytes32(
        //     keccak256(
        //         "getError((uint8, string, string[], uint256, bytes, bytes))"
        //     )
        // );
        // console.log(request.path);

        // console.log("success decoding");

        // Message will be set in `handleRoute`.
        uint256 returnDataSize;
        HttpMessages.Response memory response = handleNotFound(request, "");
        H.html("hello");
        assembly {
            returnDataSize := returndatasize()
        }
        console.log("return data size");
        console.log(returnDataSize);
        handleNotFound(request, "");
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
