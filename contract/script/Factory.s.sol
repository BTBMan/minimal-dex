// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Factory} from "../src/core/Factory.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract FactoryScript is Script, HelperConfig {
    function setUp() public {}

    function run() public returns (Factory factory) {
        vm.startBroadcast();

        factory = new Factory();

        vm.stopBroadcast();
    }
}
