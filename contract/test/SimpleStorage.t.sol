// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStorage} from "../src/SimpleStorage.sol";
import {SimpleStorageScript} from "../script/SimpleStorage.s.sol";
import {HelperConfig, IHelperConfig} from "../script/HelperConfig.s.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleStorageTest is Test, IHelperConfig {
    NetworkConfig public activeNetworkConfig;

    SimpleStorage public simpleStorage;
    HelperConfig public helperConfig;

    address public user = makeAddr("user");

    uint256 public constant STARTING_BALANCE = 1 ether;

    function setUp() public {
        (simpleStorage, helperConfig) = new SimpleStorageScript().run();
        activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        vm.deal(user, STARTING_BALANCE);
    }

    function test_FavoriteNumber() public {
        vm.startPrank(user);
        simpleStorage.store(15);
        vm.stopPrank();

        assertEq(simpleStorage.favoriteNumber(), 15);
    }
}
