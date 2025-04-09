// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {HelperConfig, IHelperConfig} from "./HelperConfig.s.sol";

contract SimpleStorageScript is Script, IHelperConfig {
    function setUp() public {}

    function run() public returns (SimpleStorage simpleStorage, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        // NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast();

        simpleStorage = new SimpleStorage();

        vm.stopBroadcast();

        return (simpleStorage, helperConfig);
    }
}
