// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract SwapRouterScript is Script, HelperConfig {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function setUp() public {}

    function run() public returns (SwapRouter swapRouter) {
        vm.startBroadcast();

        swapRouter = new SwapRouter(factory);

        vm.stopBroadcast();
    }
}
