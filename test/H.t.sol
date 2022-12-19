// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {H} from "../src/html-dsl/H.sol";

contract HTest is Test {
    function testH() public {
        assertEq(H.h("test"), "<test></test>");
    }
}
