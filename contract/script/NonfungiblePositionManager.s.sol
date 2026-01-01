// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {HelperConfig, IHelperConfig} from "./HelperConfig.s.sol";

contract NonfungiblePositionManagerScript is Script, IHelperConfig {
    function setUp() public {}

    function run() public returns (NonfungiblePositionManager nonfungiblePositionManager, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        // NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast();

        nonfungiblePositionManager = new NonfungiblePositionManager();

        vm.stopBroadcast();

        return (nonfungiblePositionManager, helperConfig);
    }
}
