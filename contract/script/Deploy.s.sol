// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {FactoryScript} from "./Factory.s.sol";
import {SwapRouterScript} from "./SwapRouter.s.sol";
import {QuoterScript} from "./Quoter.s.sol";
import {NonfungiblePositionManagerScript} from "./NonfungiblePositionManager.s.sol";
import {NonfungibleTokenPositionDescriptorScript} from "./NonfungibleTokenPositionDescriptor.s.sol";

import {Factory} from "../src/core/Factory.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import {Quoter} from "../src/periphery/lens/Quoter.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";
import {NonfungibleTokenPositionDescriptor} from "../src/periphery/NonfungibleTokenPositionDescriptor.sol";

/**
 * @title Public Deploy
 * @notice Deploy Factory、SwapRouter、NonfungiblePositionManager sequentially。
 */
contract DeployScript is Script, HelperConfig {
    function run()
        public
        returns (
            Factory factory,
            NonfungibleTokenPositionDescriptor nonfungibleTokenPositionDescriptor,
            NonfungiblePositionManager nonfungiblePositionManager,
            SwapRouter swapRouter,
            Quoter quoter
        )
    {
        vm.startBroadcast(activeNetworkConfig.deployerKey);

        // ── Deploy Factory Contract ──────────────────────────
        factory = new FactoryScript().run();
        console.log("Factory deployed at:                   ", address(factory));

        // ── Deploy NonfungibleTokenPositionDescriptor Contract ──────────────────────────
        nonfungibleTokenPositionDescriptor = new NonfungibleTokenPositionDescriptorScript().run();
        console.log("NonfungibleTokenPositionDescriptor deployed at:", address(nonfungibleTokenPositionDescriptor));

        // ── Deploy NonfungiblePositionManager Contract ──────────────────────────
        nonfungiblePositionManager =
            new NonfungiblePositionManagerScript(address(factory), address(nonfungibleTokenPositionDescriptor)).run();
        console.log("NonfungiblePositionManager deployed at:", address(nonfungiblePositionManager));

        // ── Deploy SwapRouter Contract ──────────────────────────
        swapRouter = new SwapRouterScript(address(factory)).run();
        console.log("SwapRouter deployed at:                ", address(swapRouter));

        // ── Deploy Quoter Contract ──────────────────────────
        quoter = new QuoterScript(address(factory)).run();
        console.log("Quoter deployed at:                    ", address(quoter));

        vm.stopBroadcast();
    }
}
