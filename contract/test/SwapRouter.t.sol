// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {SwapRouterScript} from "../script/SwapRouter.s.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {SwapRouter} from "../src/periphery/SwapRouter.sol";

/* Interfaces ****/
import {ISwapRouter} from "../src/interfaces/ISwapRouter.sol";

/* Libraries *****/

contract SwapRouterTest is Test, TestUtils {
    SwapRouter swapRouter;

    function setUp() public override {
        super.setUp();
    }

    function setupTestCase(PoolParams memory poolParams)
        public
        override
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        (poolBalance0, poolBalance1) = super.setupTestCase(poolParams);

        swapRouter = new SwapRouterScript(address(factory)).run();
    }

    // function testExactInputUSDCToETHInSinglePoolSuccess() public {
    //     LiquidityRange[] memory liquidity = new LiquidityRange[](1);
    //     liquidity[0] = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
    //     PoolParams memory poolParams = PoolParams({
    //         wethBalance: 1 ether,
    //         usdcBalance: 5000 ether,
    //         currentPrice: 5000,
    //         liquidity: liquidity,
    //         shouldTransferInCallback: true,
    //         mintLiquidity: true
    //     });
    //     (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

    //     uint256 swapAmount = 42 ether;

    //     // Mint and Approve some USDC tokens to the current test contract
    //     token1.mint(address(this), swapAmount);
    //     token1.approve(address(this), swapAmount);

    //     swapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
    //         tokenIn: address(0),
    //         tokenOut: address(1),
    //         tickSpacing: 1,
    //         amountIn: 1e18,
    //         sqrtPriceLimitX96: 0,
    //     }));
    // }
}
