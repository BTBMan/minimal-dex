// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {NonfungiblePositionManagerScript} from "../script/NonfungiblePositionManager.s.sol";
import {Pool} from "../src/core/Pool.sol";
import {Factory} from "../src/core/Factory.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";

/* Interfaces ****/
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

/* Libraries *****/

contract NonfungiblePositionManagerTest is Test, TestUtils {
    NonfungiblePositionManager nonfungiblePositionManager;

    function setUp() public override {
        super.setUp();
    }

    function setupTestCase(MintParams memory mintParams) public returns (uint256 poolBalance0, uint256 poolBalance1) {
        pool = Pool(factory.createPool(address(weth), address(usdc), 1));
        pool.initialize(sqrtP(mintParams.currentPrice));

        nonfungiblePositionManager = new NonfungiblePositionManagerScript(address(factory)).run();

        // Mint tokens to this test contract
        weth.mint(address(this), mintParams.wethBalance);
        usdc.mint(address(this), mintParams.usdcBalance);

        if (mintParams.mintLiquidity) {
            // Approve the nonfungiblePositionManager to spend the tokens
            weth.approve(address(nonfungiblePositionManager), mintParams.amount0Desired);
            usdc.approve(address(nonfungiblePositionManager), mintParams.amount1Desired);

            (poolBalance0, poolBalance1) = nonfungiblePositionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: address(weth),
                    token1: address(usdc),
                    recipient: address(this),
                    tickLower: mintParams.tickLower,
                    tickUpper: mintParams.tickUpper,
                    amount0Desired: mintParams.amount0Desired,
                    amount1Desired: mintParams.amount1Desired,
                    amount0Min: mintParams.amount0Min,
                    amount1Min: mintParams.amount1Min
                })
            );
        }
    }

    function testInitializeSuccess() public {
        nonfungiblePositionManager = new NonfungiblePositionManagerScript(address(factory)).run();

        uint160 initializedSqrtPriceX96 = sqrtP(5000);

        pool = Pool(
            nonfungiblePositionManager.createAndInitializePoolIfNecessary(
                address(weth), address(usdc), 1, initializedSqrtPriceX96
            )
        );

        (uint160 sqrtPriceX96,,,,) = pool.slot0();

        assertEq(sqrtPriceX96, initializedSqrtPriceX96);
    }

    function testAddPositionSuccess() public {
        MintParams memory mintParams = MintParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            tickLower: tick(4540),
            tickUpper: tick(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0,
            mintLiquidity: true
        });
        setupTestCase(mintParams);

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        assertBalances(
            ExpectedBalances({
                pool: pool,
                tokens: [weth, usdc],
                userBalance0: mintParams.wethBalance - expectedAmount0,
                userBalance1: mintParams.usdcBalance - expectedAmount1,
                poolBalance0: expectedAmount0,
                poolBalance1: expectedAmount1
            })
        );
    }

    function testAddPositionOutOfSlippage() public {
        MintParams memory mintParams = MintParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            tickLower: tick(4540),
            tickUpper: tick(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 1 ether,
            amount1Min: 5000 ether,
            mintLiquidity: false
        });
        setupTestCase(mintParams);

        weth.approve(address(nonfungiblePositionManager), mintParams.amount0Desired);
        usdc.approve(address(nonfungiblePositionManager), mintParams.amount1Desired);

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                INonfungiblePositionManager.SlippageCheckFailed.selector, expectedAmount0, expectedAmount1
            )
        );
        nonfungiblePositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: address(weth),
                token1: address(usdc),
                recipient: address(this),
                tickLower: mintParams.tickLower,
                tickUpper: mintParams.tickUpper,
                amount0Desired: mintParams.amount0Desired,
                amount1Desired: mintParams.amount1Desired,
                amount0Min: mintParams.amount0Min,
                amount1Min: mintParams.amount1Min
            })
        );
    }
}
