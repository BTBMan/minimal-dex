// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract NonfungiblePositionManagerScript is Script, HelperConfig {
    address public immutable factory;
    address public immutable nonfungibleTokenPositionDescriptor;

    constructor(address _factory, address _nonfungibleTokenPositionDescriptor) {
        factory = _factory;
        nonfungibleTokenPositionDescriptor = _nonfungibleTokenPositionDescriptor;
    }

    function setUp() public {}

    function run() public returns (NonfungiblePositionManager nonfungiblePositionManager) {
        vm.startBroadcast();

        nonfungiblePositionManager = new NonfungiblePositionManager(factory, nonfungibleTokenPositionDescriptor);

        vm.stopBroadcast();
    }
}
