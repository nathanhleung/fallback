// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./StringConcat.sol";

/**
 * Basic Solidity HTML DSL
 *
 * TODO(nathanhleung): maybe codegen this? and concat internally
 */
library H {
    function customTag(string memory tagName, string memory children)
        internal
        returns (string memory)
    {
        return
            StringConcat.concat(
                "<",
                tagName,
                ">",
                children,
                "</",
                tagName,
                ">"
            );
    }

    function customSelfClosingTag(string memory tagName)
        internal
        returns (string memory)
    {
        return StringConcat.concat("<", tagName, "/>");
    }

    function customTagWithAttributes(
        string memory tagName,
        string memory attributes,
        string memory children
    ) internal returns (string memory) {
        return
            StringConcat.concat(
                "<",
                tagName,
                " ",
                attributes,
                ">",
                children,
                "</",
                tagName,
                ">"
            );
    }

    function customSelfClosingTagWithAttributes(
        string memory tagName,
        string memory attributes
    ) internal returns (string memory) {
        return StringConcat.concat("<", tagName, " ", attributes, "/>");
    }

    function html(string memory children) internal returns (string memory) {
        return
            StringConcat.concat("<!DOCTYPE html>", customTag("html", children));
    }

    function head(string memory children) internal returns (string memory) {
        return customTag("head", children);
    }

    function title(string memory children) internal returns (string memory) {
        return customTag("title", children);
    }

    function metaWithAttributes(
        string memory attributes,
        string memory children
    ) internal returns (string memory) {
        return customTagWithAttributes("meta", attributes, children);
    }

    function body(string memory children) internal returns (string memory) {
        return customTag("body", children);
    }

    function h1(string memory children) internal returns (string memory) {
        return customTag("h1", children);
    }

    function h2(string memory children) internal returns (string memory) {
        return customTag("h2", children);
    }

    function p(string memory children) internal returns (string memory) {
        return customTag("p", children);
    }

    function ul(string memory children) internal returns (string memory) {
        return customTag("ul", children);
    }

    function li(string memory children) internal returns (string memory) {
        return customTag("li", children);
    }

    function aWithAttributes(string memory attributes, string memory children)
        internal
        returns (string memory)
    {
        return customTagWithAttributes("a", attributes, children);
    }

    function i(string memory children) internal returns (string memory) {
        return customTag("i", children);
    }

    function hr() internal returns (string memory) {
        return customSelfClosingTag("hr");
    }

    function br() internal returns (string memory) {
        return customSelfClosingTag("br");
    }

    function formWithAttributes(
        string memory attributes,
        string memory children
    ) internal returns (string memory) {
        return customTagWithAttributes("form", attributes, children);
    }

    function inputWithAttributes(string memory attributes)
        internal
        returns (string memory)
    {
        return customSelfClosingTagWithAttributes("input", attributes);
    }

    function buttonWithAttributes(
        string memory attributes,
        string memory children
    ) internal returns (string memory) {
        return customTagWithAttributes("button", attributes, children);
    }
}