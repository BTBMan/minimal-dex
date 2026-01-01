// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import {HelperConfig, IHelperConfig} from "./HelperConfig.s.sol";

contract SwapRouterScript is Script, IHelperConfig {
    function setUp() public {}

    function run() public returns (SwapRouter swapRouter, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        // NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast();

        swapRouter = new SwapRouter();

        vm.stopBroadcast();

        return (swapRouter, helperConfig);
    }
}
