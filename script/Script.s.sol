// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Test {
    function testRevert() public returns (bool) {
        revert("oops!!");
    }
}

contract ScriptTest is Script {
    function run() public {
        Test test = new Test();
        (bool success, bytes memory data) = address(test).call(
            abi.encodeWithSignature("testRevert()")
        );
        console.logBytes(data);
    }
}
