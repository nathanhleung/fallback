// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {SimpleExampleApp} from "../../example/SimpleExample.sol";
import {HttpHandler} from "../HttpHandler.sol";

contract HttpHandlerTest is Test {
    HttpHandler public httpHandler;

    function setUp() public {
        httpHandler = new HttpHandler(new SimpleExampleApp());
    }

    function testHandler() public {}
}
