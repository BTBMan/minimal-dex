// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract NonfungiblePositionManagerScript is Script, HelperConfig {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function setUp() public {}

    function run() public returns (NonfungiblePositionManager nonfungiblePositionManager) {
        vm.startBroadcast();

        nonfungiblePositionManager = new NonfungiblePositionManager(factory);

        vm.stopBroadcast();
    }
}
