// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title StringCase, a library of string casing utilities.
 */
library StringCase {
    /**
     * @notice Based on https://gist.github.com/ottodevs/c43d0a8b4b891ac2da675f825b1d1dbf
     * @dev Lowercases all letters in a string
     * @param str The string to lowercase
     */
    function toLowerCase(string memory str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= hex"41") && (bStr[i] <= hex"5A")) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
