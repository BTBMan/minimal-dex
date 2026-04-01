// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NonfungibleTokenPositionDescriptor} from "../src/periphery/NonfungibleTokenPositionDescriptor.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract NonfungibleTokenPositionDescriptorScript is Script, HelperConfig {
    function setUp() public {}

    function run() public returns (NonfungibleTokenPositionDescriptor nonfungibleTokenPositionDescriptor) {
        vm.startBroadcast();

        nonfungibleTokenPositionDescriptor = new NonfungibleTokenPositionDescriptor();

        vm.stopBroadcast();
    }
}
