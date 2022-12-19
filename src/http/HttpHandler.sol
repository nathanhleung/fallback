// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "../html-dsl/H.sol";
import {StringConcat} from "../strings/StringConcat.sol";
import {WebApp} from "../WebApp.sol";
import {HttpConstants} from "./HttpConstants.sol";
import {HttpMessages} from "./HttpMessages.sol";

/**
 * @title HttpHandler, takes `Request`s and returns `Response`s.
 * @dev Maps HTTP requests to the correct routes in the `WebApp`,
 *     and returns HTTP response data.
 */
contract HttpHandler {
    using StringConcat for string;
    using Strings for uint256;

    WebApp public app;

    constructor(WebApp webApp) {
        app = webApp;
    }

    /**
     * @dev Calls the correct function on the web app contract based
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

        HttpMessages.Response memory response;
        for (uint256 i = 0; i < possibleSignatures.length; i += 1) {
            response = safeCallApp(
                request,
                routeHandlerName.concat(possibleSignatures[i])
            );

            // If we found a valid route, return the successful
            // response.
            if (response.statusCode != 404) {
                return response;
            }
        }

        // If we got through the for loop without ever getting
        // a non-404 response back, just return the 404.
        return
            app.handleNotFound(
                request,
                StringConcat.concat(request.path, " not found on this server")
            );
    }

    /**
     * @dev Calls the function on the app contract with the given
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

        HttpMessages.Response memory response = abi.decode(
            data,
            (HttpMessages.Response)
        );

        return response;
    }
}
