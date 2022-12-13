// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./StringConcat.sol";
import "./StringCompare.sol";

/**
 * Basic Solidity HTML DSL
 *
 * TODO(nathanhleung): maybe codegen this? and concat internally
 */
library H {
    function h(string memory tagName) internal pure returns (string memory) {
        return HInternal.customTag(tagName);
    }

    function h(string memory tagName, string memory childrenOrAttributes)
        internal
        pure
        returns (string memory)
    {
        return HInternal.customTag(tagName, childrenOrAttributes);
    }

    function h(
        string memory tagName,
        string memory attributes,
        string memory children
    ) internal pure returns (string memory) {
        return HInternal.customTag(tagName, attributes, children);
    }

    function html(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("html", children);
    }

    function html5(string memory children)
        internal
        pure
        returns (string memory)
    {
        return StringConcat.concat("<!DOCTYPE html>", html(children));
    }

    function head(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("head", children);
    }

    function style(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("style", children);
    }

    function title(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("title", children);
    }

    function meta(string memory attributes)
        internal
        pure
        returns (string memory)
    {
        return h("meta", attributes);
    }

    function link(string memory attributes)
        internal
        pure
        returns (string memory)
    {
        return h("link", attributes);
    }

    function body(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("body", children);
    }

    function h1(string memory children) internal pure returns (string memory) {
        return h("h1", children);
    }

    function h2(string memory children) internal pure returns (string memory) {
        return h("h2", children);
    }

    function p(string memory children) internal pure returns (string memory) {
        return h("p", children);
    }

    function span(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("span", children);
    }

    function div(string memory children) internal pure returns (string memory) {
        return h("div", children);
    }

    function div(string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("div", attributes, children);
    }

    function ul(string memory children) internal pure returns (string memory) {
        return h("ul", children);
    }

    function li(string memory children) internal pure returns (string memory) {
        return h("li", children);
    }

    function pre(string memory children) internal pure returns (string memory) {
        return h("pre", children);
    }

    function code(string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("code", children);
    }

    function a(string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("a", attributes, children);
    }

    function i(string memory children) internal pure returns (string memory) {
        return h("i", children);
    }

    function hr() internal pure returns (string memory) {
        return h("hr");
    }

    function br() internal pure returns (string memory) {
        return h("br");
    }

    function form(string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("form", attributes, children);
    }

    function label(string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("label", attributes, children);
    }

    function input(string memory attributes)
        internal
        pure
        returns (string memory)
    {
        return h("input", attributes);
    }

    function button(string memory attributes, string memory children)
        internal
        pure
        returns (string memory)
    {
        return h("button", attributes, children);
    }
}

/**
 * A component library of already-styled components.
 */
library HComponents {
    struct NavbarLink {
        string href;
        string children;
    }

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
                // https://css-tricks.com/snippets/css/system-font-stack/
            );
    }

    function navbar(NavbarLink[] memory links)
        internal
        pure
        returns (string memory)
    {
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
}

/**
 * Functions used to build the `H` DSL.
 */
library HInternal {
    function isSelfClosing(string memory tagName) internal pure returns (bool) {
        // TODO(nathanhleung) get list of self-closing tags
        if (
            StringCompare.equals(tagName, "meta") ||
            StringCompare.equals(tagName, "link") ||
            StringCompare.equals(tagName, "br") ||
            StringCompare.equals(tagName, "hr") ||
            StringCompare.equals(tagName, "input")
        ) {
            return true;
        }
        return false;
    }

    function customTag(string memory tagName)
        internal
        pure
        returns (string memory)
    {
        if (HInternal.isSelfClosing(tagName)) {
            return StringConcat.concat("<", tagName, "/>");
        }

        return customTag(tagName, "");
    }

    function customTag(
        string memory tagName,
        string memory attributesOrChildren
    ) internal pure returns (string memory) {
        if (HInternal.isSelfClosing(tagName)) {
            return
                StringConcat.concat(
                    "<",
                    tagName,
                    " ",
                    attributesOrChildren,
                    "/>"
                );
        }

        return
            StringConcat.concat(
                "<",
                tagName,
                ">",
                attributesOrChildren,
                "</",
                tagName,
                ">"
            );
    }

    function customTag(
        string memory tagName,
        string memory attributes,
        string memory children
    ) internal pure returns (string memory) {
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
}
