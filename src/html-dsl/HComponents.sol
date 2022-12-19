// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StringConcat} from "../strings/StringConcat.sol";
import {H} from "./H.sol";

/**
 * @title HComponents, a component library using H
 * @author nathanhleung
 * @dev Include `HComponents.styles()` in your HTML response and
 *     use the components.
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
