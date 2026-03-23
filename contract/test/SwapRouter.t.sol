// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {SwapRouterScript} from "../script/SwapRouter.s.sol";
import {NonfungiblePositionManagerScript} from "../script/NonfungiblePositionManager.s.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";
import {Pool} from "../src/core/Pool.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";

/* Interfaces ****/
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

/* Libraries *****/

contract SwapRouterTest is Test, TestUtils {
    NonfungiblePositionManager nonfungiblePositionManager;
    SwapRouter swapRouter;

    ERC20Mock public usdt; // USDT
    ERC20Mock public wbtc; // BTC

    function setUp() public override {
        usdt = new ERC20Mock();
        wbtc = new ERC20Mock();

        super.setUp();
    }

    function setupTestCase(MultiplePoolParams memory mintParams)
        public
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        pool = Pool(factory.createPool(mintParams.token0, mintParams.token1, 1));
        pool.initialize(sqrtP(mintParams.currentPrice));

        nonfungiblePositionManager = new NonfungiblePositionManagerScript(address(factory)).run();

        // Mint tokens to this test contract
        ERC20Mock(mintParams.token0).mint(address(this), mintParams.token0Balance);
        ERC20Mock(mintParams.token1).mint(address(this), mintParams.token1Balance);

        if (mintParams.mintLiquidity) {
            // Approve the nonfungiblePositionManager to spend the tokens
            ERC20Mock(mintParams.token0).approve(address(nonfungiblePositionManager), mintParams.amount0Desired);
            ERC20Mock(mintParams.token1).approve(address(nonfungiblePositionManager), mintParams.amount1Desired);

            (poolBalance0, poolBalance1) = nonfungiblePositionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: mintParams.token0,
                    token1: mintParams.token1,
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

        swapRouter = new SwapRouterScript(address(factory)).run();
    }

    function testExactInputUSDCToETHInSinglePoolSuccess() public {
        MultiplePoolParams memory mintParams = MultiplePoolParams({
            token0: address(weth),
            token1: address(usdc),
            token0Balance: 1 ether,
            token1Balance: 5000 ether,
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

        uint256 swapAmount = 42 ether;

        // Mint and Approve some USDC tokens to the current test contract
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(swapRouter), swapAmount);

        uint256 amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(usdc), tokenOut: address(weth), fee: 1, amountIn: swapAmount, sqrtPriceLimitX96: 0
            })
        );

        uint256 expectedAmountOut = 0.008396837685175036 ether;

        assertEq(amountOut, expectedAmountOut);
    }

    function testExactInputETHToBTCInMultiplePoolsSuccess() public {
        MultiplePoolParams memory mintParams1 = MultiplePoolParams({
            token0: address(weth),
            token1: address(usdc),
            token0Balance: 2 ether,
            token1Balance: 10000 ether,
            currentPrice: 5000,
            tickLower: tick(4540),
            tickUpper: tick(5500),
            amount0Desired: 2 ether,
            amount1Desired: 10000 ether,
            amount0Min: 0,
            amount1Min: 0,
            mintLiquidity: true
        });
        MultiplePoolParams memory mintParams2 = MultiplePoolParams({
            token0: address(usdc),
            token1: address(usdt),
            token0Balance: 10000 ether,
            token1Balance: 10000 ether,
            currentPrice: 1,
            tickLower: tick(1),
            tickUpper: tick(2),
            amount0Desired: 10000 ether,
            amount1Desired: 10000 ether,
            amount0Min: 0,
            amount1Min: 0,
            mintLiquidity: true
        });
        MultiplePoolParams memory mintParams3 = MultiplePoolParams({
            token0: address(wbtc),
            token1: address(usdt),
            token0Balance: 1 ether,
            token1Balance: 10000 ether,
            currentPrice: 10000,
            tickLower: tick(9000),
            tickUpper: tick(15000),
            amount0Desired: 1 ether,
            amount1Desired: 10000 ether,
            amount0Min: 0,
            amount1Min: 0,
            mintLiquidity: true
        });
        setupTestCase(mintParams1);
        setupTestCase(mintParams2);
        setupTestCase(mintParams3);

        uint256 swapAmount = 1 ether;

        // Mint and Approve some ETH tokens to the current test contract
        weth.mint(address(this), swapAmount);
        weth.approve(address(swapRouter), swapAmount);

        uint256 amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParams({
                path: bytes.concat(
                    bytes20(address(weth)),
                    bytes3(uint24(1)),
                    bytes20(address(usdc)),
                    bytes3(uint24(1)),
                    bytes20(address(usdt)),
                    bytes3(uint24(1)),
                    bytes20(address(wbtc))
                ),
                recipient: address(this),
                amountIn: swapAmount,
                amountOutMinimum: 0
            })
        );

        uint256 expectedAmountOut = 0.396279562407372129 ether;

        assertEq(amountOut, expectedAmountOut);
    }
}
