// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * @title StringCompare, a library of string comparison utilities.
 */
library StringCompare {
    /**
     * @dev Determines whether two strings are equal by comparing
     *     the strings byte-by-byte.
     * @param str The first string to compare
     * @param otherStr The second string to compare
     * @return Whether the two strings are equal
     */
    function equals(string memory str, string memory otherStr)
        internal
        pure
        returns (bool)
    {
        bytes memory bStr = bytes(str);
        bytes memory bOtherStr = bytes(otherStr);

        if (bStr.length != bOtherStr.length) {
            return false;
        }

        for (uint256 i = 0; i < bOtherStr.length; i++) {
            if (bStr[i] != bOtherStr[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Determines whether one string starts with another
     *     by checking the string against the prefix byte-by-byte.
     * @param str The string to check the prefix against
     * @param prefix The prefix
     * @return Whether the string starts with the prefix
     */
    function startsWith(string memory str, string memory prefix)
        internal
        pure
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

    /**
     * @dev Determines whether one string contains another by
     *     checking byte-by-byte.
     * @param str The string that may contain the substring
     * @param substr The substring to check containment of
     * @return Whether the string contains the substring
     */
    function contains(string memory str, string memory substr)
        internal
        pure
        returns (bool)
    {
        bytes memory bStr = bytes(str);
        bytes memory bSubstr = bytes(substr);

        if (bStr.length < bSubstr.length) {
            return false;
        }

        // All strings contain the empty string
        if (bSubstr.length == 0) {
            return true;
        }

        uint256 matchedChars = 0;
        for (uint256 i = 0; i < bStr.length; i += 1) {
            // If we don't have a match, try matching
            // again from the beginning.
            if (bStr[i] != bSubstr[matchedChars]) {
                matchedChars = 0;
            }

            // If we do have a match, try to match the next
            // character
            if (bStr[i] == bSubstr[matchedChars]) {
                matchedChars += 1;
            }

            if (matchedChars == bSubstr.length) {
                return true;
            }
        }

        return false;
    }
}
