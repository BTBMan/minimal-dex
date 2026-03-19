// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FactoryScript} from "./Factory.s.sol";
import {SwapRouterScript} from "./SwapRouter.s.sol";
import {NonfungiblePositionManagerScript} from "./NonfungiblePositionManager.s.sol";

import {Factory} from "../src/core/Factory.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";

/**
 * @title Public Deploy
 * @notice Deploy Factory、SwapRouter、NonfungiblePositionManager sequentially。
 */
contract DeployScript is Script, HelperConfig {
    function run()
        public
        returns (Factory factory, SwapRouter swapRouter, NonfungiblePositionManager nonfungiblePositionManager)
    {
        vm.startBroadcast(activeNetworkConfig.deployerKey);

        // ── 1. Deploy Factory Contract ──────────────────────────
        factory = new FactoryScript().run();
        console.log("Factory deployed at:                   ", address(factory));

        // ── 2. Deploy SwapRouter Contract ──────────────────────────
        swapRouter = new SwapRouterScript(address(factory)).run();
        console.log("SwapRouter deployed at:                ", address(swapRouter));

        // ── 3. Deploy NonfungiblePositionManager Contract ──────────────────────────
        nonfungiblePositionManager = new NonfungiblePositionManagerScript(address(factory)).run();
        console.log("NonfungiblePositionManager deployed at:", address(nonfungiblePositionManager));

        vm.stopBroadcast();
    }
}
