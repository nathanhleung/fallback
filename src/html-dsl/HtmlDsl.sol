// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StringConcat} from "../strings/StringConcat.sol";
import {StringCompare} from "../strings/StringCompare.sol";

/**
 * Functions used to build the `H` DSL.
 */
library HtmlDsl {
    function isSelfClosing(string memory tagName) private pure returns (bool) {
        // List of self-closing tags taken from
        // https://html.spec.whatwg.org/multipage/syntax.html#void-elements
        if (
            StringCompare.equals(tagName, "area") ||
            StringCompare.equals(tagName, "base") ||
            StringCompare.equals(tagName, "br") ||
            StringCompare.equals(tagName, "col") ||
            StringCompare.equals(tagName, "embed") ||
            StringCompare.equals(tagName, "hr") ||
            StringCompare.equals(tagName, "img") ||
            StringCompare.equals(tagName, "input") ||
            StringCompare.equals(tagName, "link") ||
            StringCompare.equals(tagName, "meta") ||
            StringCompare.equals(tagName, "source") ||
            StringCompare.equals(tagName, "track") ||
            StringCompare.equals(tagName, "wbr")
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
        if (isSelfClosing(tagName)) {
            return StringConcat.concat("<", tagName, "/>");
        }

        return customTag(tagName, "");
    }

    function customTag(
        string memory tagName,
        string memory attributesOrChildren
    ) internal pure returns (string memory) {
        if (isSelfClosing(tagName)) {
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
        if (isSelfClosing(tagName)) {
            return StringConcat.concat("<", tagName, " ", attributes, "/>");
        }

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
