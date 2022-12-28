// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Strings} from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import {H} from "../html-dsl/H.sol";
import {HttpConstants} from "../http/HttpConstants.sol";
import {HttpMessages} from "../http/HttpMessages.sol";
import {DefaultServer} from "../HttpServer.sol";
import {StringConcat} from "../strings/StringConcat.sol";
import {WebApp} from "../WebApp.sol";

/**
 * Example web app. Add routes here.
 */
contract SimpleExampleApp is WebApp {
    constructor() {
        routes[HttpConstants.Method.GET]["/"] = "getIndex";
        routes[HttpConstants.Method.GET]["/text"] = "getText";
        routes[HttpConstants.Method.GET]["/form"] = "getForm";
        routes[HttpConstants.Method.POST]["/form"] = "postForm";
        routes[HttpConstants.Method.GET]["/debug"] = "getDebug";
        routes[HttpConstants.Method.GET]["/error"] = "getError";
        routes[HttpConstants.Method.GET]["/panic"] = "getPanic";
        routes[HttpConstants.Method.GET]["/github"] = "getGithub";
        routes[HttpConstants.Method.GET]["/json"] = "getJson";
    }

    function getIndex() external view returns (HttpMessages.Response memory) {
        string memory htmlString = H.html5(
            H.body(
                StringConcat.concat(
                    H.h1("fallback() web framework"),
                    H.p(H.i("a solidity web framework")),
                    H.div(
                        StringConcat.concat(
                            H.a("href='/text'", "Text"),
                            H.br(),
                            H.a("href='/form'", "Form"),
                            H.br(),
                            H.a("href='/debug'", "Debug"),
                            H.br(),
                            H.a("href='/error'", "Error"),
                            H.br(),
                            H.a("href='/panic'", "Panic"),
                            H.br(),
                            H.a("href='/github'", "Github"),
                            H.br(),
                            H.a("href='/json'", "JSON")
                        )
                    ),
                    H.p(
                        StringConcat.concat(
                            "This example app is deployed to ",
                            H.b(Strings.toHexString(uint160(msg.sender), 20)),
                            "."
                        )
                    )
                )
            )
        );
        return html(htmlString);
    }

    function getText() external pure returns (HttpMessages.Response memory) {
        HttpMessages.Response memory response;
        response.content = "hello world!";
        return response;
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

    function getForm() external pure returns (HttpMessages.Response memory) {
        HttpMessages.Response memory response;
        response
            .content = "curl -v -d 'random post data' -X POST http://simple.fallback.natecation.xyz/form";
        return response;
    }

    function postForm(HttpMessages.Request calldata request)
        external
        pure
        returns (HttpMessages.Response memory)
    {
        HttpMessages.Response memory response;
        response.content = StringConcat.concat(
            "Received posted data: ",
            string(request.content)
        );
        return response;
    }

    function getDebug() external view returns (HttpMessages.Response memory) {
        string memory htmlString = StringConcat.concat(
            "Debug mode: ",
            H.code(debug ? "true" : "false")
        );
        return html(htmlString);
    }

    function getError() external pure returns (HttpMessages.Response memory) {
        revert("Reverting from SimpleExampleApp.getError");
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
contract SimpleExampleServer is DefaultServer {
    constructor() DefaultServer(new SimpleExampleApp()) {
        app.setDebug(true);
    }
}
