// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Quoter} from "../src/periphery/lens/Quoter.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract QuoterScript is Script, HelperConfig {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function setUp() public {}

    function run() public returns (Quoter quoter) {
        vm.startBroadcast();

        quoter = new Quoter(factory);

        vm.stopBroadcast();
    }
}
