// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {StringCompare} from "../StringCompare.sol";

contract StringCompareTest is Test {
    function testEqualsEmpty(string memory str) public {
        assertEq(StringCompare.equals("", ""), true);
    }

    function testEqualsTrue(string memory str) public {
        assertEq(StringCompare.equals(str, str), true);
    }

    function testEqualsFalse(string memory str) public {
        vm.assume(keccak256(abi.encode(str)) != keccak256(abi.encode("hello")));
        vm.assume(keccak256(abi.encode(str)) != keccak256(abi.encode("")));

        assertEq(StringCompare.equals(str, "hello"), false);
        assertEq(StringCompare.equals(str, ""), false);
    }

    function testStartsWithTrue(string memory str1, string memory str2) public {
        assertEq(StringCompare.startsWith(str1, ""), true);
        assertEq(StringCompare.startsWith(str1, str1), true);
        assertEq(
            StringCompare.startsWith(string.concat(str1, str2), str1),
            true
        );
    }

    function testStartsWithFalse(string memory str1, string memory str2)
        public
    {
        vm.assume(keccak256(abi.encode(str1)) != keccak256(abi.encode(str2)));
        vm.assume(keccak256(abi.encode(str1)) != keccak256(abi.encode("")));
        vm.assume(keccak256(abi.encode(str2)) != keccak256(abi.encode("")));

        assertEq(StringCompare.startsWith("", str1), false);
        assertEq(
            StringCompare.startsWith(str1, string.concat(str1, str2)),
            false
        );
        assertEq(StringCompare.startsWith(str1, str2), false);
    }

    function testContainsEmpty(string memory str) public {
        assertEq(StringCompare.contains("", ""), true);
    }

    function testContainsTrue(
        string memory str1,
        string memory str2,
        string memory str3
    ) public {
        assertEq(StringCompare.contains(str1, ""), true);
        assertEq(StringCompare.contains(string.concat(str1, str2), str1), true);
        assertEq(StringCompare.contains(string.concat(str1, str2), str2), true);
        assertEq(
            StringCompare.contains(
                string.concat(string.concat(str1, str2), str3),
                str2
            ),
            true
        );
    }

    function testContainsFalse() public {}
}
