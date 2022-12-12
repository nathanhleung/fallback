// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
 * Utility functions for concatenating multiple strings together.
 */
library StringConcat {
    function concat(string memory s1, string memory s2)
        internal
        pure
        returns (string memory)
    {
        return string.concat(s1, s2);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2), s3);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2, s3), s4);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4,
        string memory s5
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2, s3, s4), s5);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4,
        string memory s5,
        string memory s6
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2, s3, s4, s5), s6);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4,
        string memory s5,
        string memory s6,
        string memory s7
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2, s3, s4, s5, s6), s7);
    }

    function concat(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4,
        string memory s5,
        string memory s6,
        string memory s7,
        string memory s8
    ) internal pure returns (string memory) {
        return concat(concat(s1, s2, s3, s4, s5, s6, s7), s8);
    }
}
