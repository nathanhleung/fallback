// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * String starts with utiity.
 */
library StringStartsWith {
    function startsWith(string memory str, string memory prefix)
        internal
        returns (bool)
    {
        bytes memory bStr = bytes(str);
        bytes memory bPrefix = bytes(prefix);

        if (bStr.length < bPrefix.length) {
            return false;
        }

        for (uint256 i = 0; i < bPrefix.length; i++) {
            if (bStr[i] != bPrefix[i]) {
                return false;
            }
        }

        return true;
    }
}
