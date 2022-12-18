// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../HttpServer.sol";
import "../WebApp.sol";
import "../utils/HttpMessages.sol";

library ExampleComponents {
    function navbar() internal pure returns (string memory) {
        HComponents.NavbarLink[] memory links = new HComponents.NavbarLink[](6);
        // Stack too deep
        {
            HComponents.NavbarLink memory homeLink;
            homeLink.href = "/";
            homeLink.children = "Home";
            links[0] = homeLink;

            HComponents.NavbarLink memory debugLink;
            debugLink.href = "/debug";
            debugLink.children = "Debug";
            links[1] = debugLink;

            HComponents.NavbarLink memory notFoundLink;
            notFoundLink.href = "/nonexistent";
            notFoundLink.children = "Nonexistent";
            links[2] = notFoundLink;

            HComponents.NavbarLink memory errorLink;
            errorLink.href = "/error";
            errorLink.children = "Error";
            links[3] = errorLink;

            HComponents.NavbarLink memory panicLink;
            panicLink.href = "/panic";
            panicLink.children = "Panic";
            links[4] = panicLink;

            HComponents.NavbarLink memory githubLink;
            githubLink.href = "/github";
            githubLink.children = "GitHub";
            links[5] = githubLink;
        }

        return HComponents.navbar(links);
    }

    /** Base layout to be used by other pages */
    function layout(string memory head, string memory body)
        internal
        returns (string memory)
    {
        return
            H.html(
                StringConcat.concat(
                    H.head(
                        StringConcat.concat(
                            H.title("fallback() Web Server"),
                            H.meta('charset="utf-8"'),
                            H.meta(
                                'name="viewport" content="width=device-width, initial-scale=1"'
                            ),
                            HComponents.styles(),
                            head
                        )
                    ),
                    H.body(StringConcat.concat(navbar(), body))
                )
            );
    }
}

/**
 * Example web app. Add routes here.
 */
contract ExampleApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.POST]["/form"] = "postForm";
        routes[HttpConstants.Method.GET]["/debug"] = "getDebug";
        routes[HttpConstants.Method.GET]["/error"] = "getError";
        routes[HttpConstants.Method.GET]["/panic"] = "getPanic";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
    }

    function getIndex() external returns (HttpMessages.Response memory) {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        HttpMessages.Response memory response;
        response.statusCode = 200;
        response.headers = responseHeaders;

        response.content = ExampleComponents.layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Framework"),
                H.p("Write web apps in Solidity"),
                H.h2("Form"),
                H.form(
                    'action="/form" method="POST"',
                    StringConcat.concat(
                        H.label('for="name"', "Name"),
                        H.br(),
                        H.input('type="text" name="name" placeholder="name"'),
                        H.br(),
                        H.br(),
                        H.label('for="favorite_number"', "Favorite Number"),
                        H.br(),
                        H.input(
                            'type="number" name="favorite_number" placeholder="favorite number"'
                        ),
                        H.br(),
                        H.br(),
                        H.button('"type="submit"', "Submit")
                    )
                ),
                H.hr(),
                H.p(H.i("fallback() web server"))
            )
        );

        return response;
    }

    function getIndex(HttpMessages.Request calldata request)
        external
        override
        returns (HttpMessages.Response memory)
    {
        return this.getIndex();
    }

    function postForm(HttpMessages.Request calldata request)
        external
        returns (HttpMessages.Response memory)
    {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        HttpMessages.Response memory response;
        response.statusCode = 200;
        response.headers = responseHeaders;
        response.content = ExampleComponents.layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Server"),
                H.p(
                    StringConcat.concat(
                        "Received posted data: ",
                        string(request.content)
                    )
                ),
                H.hr(),
                H.p(H.i("fallback() web server"))
            )
        );

        return response;
    }

    function getDebug(HttpMessages.Request calldata request)
        external
        returns (HttpMessages.Response memory)
    {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[0] = "Content-Type: text/html";

        string memory requestHeadersString = StringConcat.join(
            request.headers,
            "\r\n"
        );

        string memory responseContent = ExampleComponents.layout(
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

        HttpMessages.Response memory response;
        response.statusCode = 200;
        response.headers = responseHeaders;
        response.content = responseContent;
        return response;
    }

    function getError() external pure returns (HttpMessages.Response memory) {
        revert("Reverting from ExampleApp.getError");
    }

    function getPanic() external pure returns (HttpMessages.Response memory) {
        string[] memory stringArray = new string[](0);
        stringArray[1] = "This will cause a panic.";
    }

    function getGithub() external pure returns (HttpMessages.Response memory) {
        string[] memory responseHeaders = new string[](1);
        responseHeaders[
            0
        ] = "Location: https://github.com/nathanhleung/fallback";

        HttpMessages.Response memory response;
        // response.statusCode = 302;
        response.headers = responseHeaders;

        return response;
    }
}

/**
 * Example web server. Wraps the web app contract in HTTP request
 * parsing code, sends proper HTTP responses.
 */
contract ExampleServer is DefaultServer {
    constructor() DefaultServer(new ExampleApp()) {
        app.setDebug(true);
    }
}
