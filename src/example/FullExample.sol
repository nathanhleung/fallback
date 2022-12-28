// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "../html-dsl/H.sol";
import {HttpConstants} from "../http/HttpConstants.sol";
import {HttpMessages} from "../http/HttpMessages.sol";
import {DefaultServer} from "../HttpServer.sol";
import {StringConcat} from "../strings/StringConcat.sol";
import {WebApp} from "../WebApp.sol";

library FullExampleComponents {
    struct NavbarLink {
        string href;
        string children;
    }

    /**
     * @dev Native system font stack. Copied from
     *     https://css-tricks.com/snippets/css/system-font-stack/
     */
    string constant SYSTEM_FONTS =
        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol"';

    function styles() internal pure returns (string memory) {
        return
            H.style(
                StringConcat.concat(
                    "body {"
                    "font-family: ",
                    SYSTEM_FONTS,
                    ";",
                    "padding: 50px;"
                    "}"
                    ".navbar > ul { list-style-type: none; padding: 0; }"
                    ".navbar > ul > li { display: inline-block; margin-right: 40px; }"
                )
            );
    }

    function navbar() internal pure returns (string memory) {
        NavbarLink[] memory links = new NavbarLink[](7);

        NavbarLink memory homeLink;
        homeLink.href = "/";
        homeLink.children = "Home";
        links[0] = homeLink;

        NavbarLink memory debugLink;
        debugLink.href = "/debug";
        debugLink.children = "Debug";
        links[1] = debugLink;

        NavbarLink memory notFoundLink;
        notFoundLink.href = "/nonexistent";
        notFoundLink.children = "Nonexistent";
        links[2] = notFoundLink;

        NavbarLink memory errorLink;
        errorLink.href = "/error";
        errorLink.children = "Error";
        links[3] = errorLink;

        NavbarLink memory panicLink;
        panicLink.href = "/panic";
        panicLink.children = "Panic";
        links[4] = panicLink;

        NavbarLink memory githubLink;
        githubLink.href = "/github";
        githubLink.children = "GitHub";
        links[5] = githubLink;

        NavbarLink memory jsonLink;
        jsonLink.href = "/json";
        jsonLink.children = "JSON";
        links[6] = jsonLink;

        string memory lis = "";
        for (uint256 i = 0; i < links.length; i += 1) {
            lis = StringConcat.concat(
                lis,
                (
                    H.li(
                        H.a(
                            StringConcat.concat('href="', links[i].href, '"'),
                            links[i].children
                        )
                    )
                )
            );
        }

        return H.div("class='navbar'", H.ul(lis));
    }

    /** Base layout to be used by other pages */
    function layout(string memory head, string memory body)
        internal
        pure
        returns (string memory)
    {
        return
            H.html(
                StringConcat.concat(
                    H.head(
                        StringConcat.concat(
                            H.title("fallback() Web Framework"),
                            H.meta('charset="utf-8"'),
                            H.meta(
                                'name="viewport" content="width=device-width, initial-scale=1"'
                            ),
                            styles(),
                            head
                        )
                    ),
                    H.body(
                        StringConcat.concat(navbar(), H.main(body), footer())
                    )
                )
            );
    }

    function footer() internal pure returns (string memory) {
        return
            H.footer(
                StringConcat.concat(
                    H.hr(),
                    H.p(H.i("fallback() web framework"))
                )
            );
    }
}

/**
 * Example web app. Add routes here.
 */
contract FullExampleApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.POST]["/form"] = "postForm";
        routes[HttpConstants.Method.GET]["/debug"] = "getDebug";
        routes[HttpConstants.Method.GET]["/error"] = "getError";
        routes[HttpConstants.Method.GET]["/panic"] = "getPanic";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
        routes[HttpConstants.Method.GET]["/json"] = "getJson";
    }

    function getIndex() external pure returns (HttpMessages.Response memory) {
        string memory htmlString = FullExampleComponents.layout(
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
                )
            )
        );

        return html(htmlString);
    }

    function getIndex(HttpMessages.Request calldata request)
        external
        view
        override
        returns (HttpMessages.Response memory)
    {
        request;
        return this.getIndex();
    }

    function postForm(HttpMessages.Request calldata request)
        external
        pure
        returns (HttpMessages.Response memory)
    {
        string memory htmlString = FullExampleComponents.layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Framework"),
                H.p(
                    StringConcat.concat(
                        "Received posted data: ",
                        string(request.content)
                    )
                )
            )
        );

        return html(htmlString);
    }

    function getDebug(HttpMessages.Request calldata request)
        external
        view
        returns (HttpMessages.Response memory)
    {
        string memory requestHeadersString = StringConcat.join(
            request.headers,
            "\r\n"
        );

        string memory htmlString = FullExampleComponents.layout(
            "",
            StringConcat.concat(
                H.h1("fallback() Web Framework"),
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
                H.p(
                    StringConcat.concat(
                        "HttpServer address: ",
                        H.code(Strings.toHexString(uint160(serverAddress), 20))
                    )
                ),
                H.p("Request headers:"),
                H.pre(requestHeadersString)
            )
        );

        return html(htmlString);
    }

    function getError() external pure returns (HttpMessages.Response memory) {
        revert("Reverting from ExampleApp.getError");
    }

    function getPanic()
        external
        pure
        returns (HttpMessages.Response memory response)
    {
        string[] memory stringArray = new string[](0);
        stringArray[1] = "This will cause a panic.";
        return response;
    }

    function getGithub() external pure returns (HttpMessages.Response memory) {
        return redirect(302, "https://github.com/nathanhleung/fallback");
    }

    function getJson() external pure returns (HttpMessages.Response memory) {
        return json('{"key": "value"}');
    }
}

/**
 * Example HTTP server. Wraps the web app contract in HTTP request
 * parsing code, sends proper HTTP responses.
 */
contract FullExampleServer is DefaultServer {
    constructor() DefaultServer(new FullExampleApp()) {
        app.setDebug(true);
    }
}
