pragma solidity ^0.8.13;

/**
 * Library for working with integers.
 */
library Integers {
    /**
     * Converts a string to an int.
     *
     * https://ethereum.stackexchange.com/a/18035
     */
    function parseInt(string memory s) internal pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] >= hex"30" && b[i] <= hex"39") {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }
}
