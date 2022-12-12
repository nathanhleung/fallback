// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../HttpServer.sol";
import "../WebApp.sol";
import "../utils/HttpMessages.sol";

/**
 * Example web app. Add routes here.
 */
contract ExampleApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.POST]["/form"] = "postForm";
        routes[HttpConstants.Method.GET]["/debug"] = "getDebug";
        routes[HttpConstants.Method.GET]["/error"] = "getError";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
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

        responseContent = H.html(
            StringConcat.concat(
                H.head(H.title("fallback() Web Server")),
                H.body(
                    StringConcat.concat(
                        H.h1("fallback() Web Server"),
                        H.p("What hath god wrought?"),
                        H.h2("Form"),
                        H.formWithAttributes(
                            'action="/form" method="POST"',
                            StringConcat.concat(
                                H.inputWithAttributes(
                                    'type="text" name="name" placeholder="name"'
                                ),
                                H.br(),
                                H.inputWithAttributes(
                                    'type="number" name="favorite_number" placeholder="favorite number"'
                                ),
                                H.br(),
                                H.buttonWithAttributes(
                                    '"type="submit"',
                                    "Submit"
                                )
                            )
                        ),
                        H.h2("Links"),
                        H.ul(
                            StringConcat.concat(
                                H.li(
                                    H.aWithAttributes('href="/debug"', "/debug")
                                ),
                                H.li(
                                    H.aWithAttributes('href="/error"', "/error")
                                ),
                                H.li(
                                    H.aWithAttributes(
                                        'href="/github"',
                                        "/github"
                                    )
                                )
                            )
                        ),
                        H.hr(),
                        H.p(H.i("fallback() web server"))
                    )
                )
            )
        );

        return (statusCode, responseHeaders, responseContent);
    }

    function postForm(
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
        statusCode = 200;

        responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        responseContent = H.html(
            StringConcat.concat(
                H.head(H.title("fallback() Web Server")),
                H.body(
                    StringConcat.concat(
                        H.h1("fallback() Web Server"),
                        H.p(
                            StringConcat.concat(
                                "Received posted data: ",
                                string(requestContent)
                            )
                        ),
                        H.hr(),
                        H.p(H.i("fallback() web server"))
                    )
                )
            )
        );

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
        statusCode = 200;

        responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        responseContent = H.html(
            StringConcat.concat(
                H.head(H.title("fallback() Web Server")),
                H.body(
                    StringConcat.concat(
                        H.h1("fallback() Web Server"),
                        H.p(
                            StringConcat.concat(
                                "Debug mode: ",
                                debug ? "true" : "false"
                            )
                        ),
                        H.p(
                            StringConcat.concat(
                                "ExampleApp address: ",
                                Strings.toHexString(uint160(address(this)), 20)
                            )
                        ),
                        H.p(
                            StringConcat.concat(
                                "HttpHandler address: ",
                                Strings.toHexString(uint160(msg.sender), 20)
                            )
                        ),
                        H.hr(),
                        H.p(H.i("fallback() web server"))
                    )
                )
            )
        );

        return (statusCode, responseHeaders, responseContent);
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
        revert("Reverting from ExampleApp.getError");
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
}

/**
 * Example web server. Wraps the web app contract in HTTP request
 * parsing code, sends proper HTTP responses.
 */
contract ExampleServer is HttpServer {
    constructor() HttpServer(new ExampleApp()) {
        app.setDebug(true);
    }
}
