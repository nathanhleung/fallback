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

    /** Base layout to be used by other pages */
    function layout(string memory head, string memory body)
        private
        returns (string memory)
    {
        return
            H.html(
                StringConcat.concat(
                    H.head(
                        StringConcat.concat(
                            H.title("fallback() Web Server"),
                            H.metaWithAttributes('charset="utf-8"'),
                            H.metaWithAttributes(
                                'name="viewport" content="width=device-width, initial-scale=1"'
                            ),
                            H.style(
                                // https://css-tricks.com/snippets/css/system-font-stack/
                                "body {"
                                'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";'
                                "padding: 50px;"
                                "}"
                                ".navbar > ul { list-style-type: none; padding: 0; }"
                                ".navbar > ul > li { display: inline-block; margin-right: 40px; }"
                            ),
                            head
                        )
                    ),
                    H.body(
                        StringConcat.concat(
                            H.divWithAttributes(
                                "class='navbar'",
                                H.ul(
                                    StringConcat.concat(
                                        H.li(
                                            H.aWithAttributes(
                                                'href="/"',
                                                "Home"
                                            )
                                        ),
                                        H.li(
                                            H.aWithAttributes(
                                                'href="/debug"',
                                                "Debug"
                                            )
                                        ),
                                        H.li(
                                            H.aWithAttributes(
                                                'href="/nonexistent"',
                                                "Not Found"
                                            )
                                        ),
                                        H.li(
                                            H.aWithAttributes(
                                                'href="/error"',
                                                "Error"
                                            )
                                        ),
                                        H.li(
                                            H.aWithAttributes(
                                                'href="/github"',
                                                "Github"
                                            )
                                        )
                                    )
                                )
                            ),
                            body
                        )
                    )
                )
            );
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

        responseContent = layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Framework"),
                H.p("Write web apps in Solidity"),
                H.h2("Form"),
                H.formWithAttributes(
                    'action="/form" method="POST"',
                    StringConcat.concat(
                        H.labelWithAttributes('for="name"', "Name"),
                        H.br(),
                        H.inputWithAttributes(
                            'type="text" name="name" placeholder="name"'
                        ),
                        H.br(),
                        H.br(),
                        H.labelWithAttributes(
                            'for="favorite_number"',
                            "Favorite Number"
                        ),
                        H.br(),
                        H.inputWithAttributes(
                            'type="number" name="favorite_number" placeholder="favorite number"'
                        ),
                        H.br(),
                        H.br(),
                        H.buttonWithAttributes('"type="submit"', "Submit")
                    )
                ),
                H.hr(),
                H.p(H.i("fallback() web server"))
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

        responseContent = layout(
            "",
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

        // Construct in block to avoid stack too deep error
        string memory requestHeadersString;
        {
            requestHeadersString = StringConcat.concat(requestHeaders, "\r\n");
        }

        responseContent = layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Server"),
                H.p(
                    StringConcat.concat(
                        "Debug mode: ",
                        H.code(debug ? "true" : "false")
                    )
                ),
                H.p(
                    StringConcat.concat(
                        "ExampleApp address: ",
                        H.code(Strings.toHexString(uint160(address(this)), 20))
                    )
                ),
                H.p(
                    StringConcat.concat(
                        "HttpHandler address: ",
                        H.code(Strings.toHexString(uint160(msg.sender), 20))
                    )
                ),
                H.p("Request headers:"),
                H.pre(requestHeadersString),
                H.hr(),
                H.p(H.i("fallback() web server"))
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
