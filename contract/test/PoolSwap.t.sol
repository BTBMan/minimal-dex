// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Pool} from "../src/core/Pool.sol";
import {TestUtils} from "./utils/TestUtils.sol";

/* Interfaces ****/

/* Libraries *****/

contract PoolSwapTest is Test, TestUtils {
    function setUp() public override {
        super.setUp();
    }

    function testBuyETHOnePriceRange() public {
        // Define a liquidity range array with 1 length
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        PoolParams memory poolParams = PoolParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 42 ether;

        // Mint and Approve some USDC tokens to the current test contract
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-0.008396837685175036 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: 5604440321401375301926914693788, // 5003.862075243974
                tick: 85183,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    function testBuyUSDCOnePriceRange() public {
        // Define a liquidity range array with 1 length
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        PoolParams memory poolParams = PoolParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 0.01337 ether;

        // Mint and Approve some ETH tokens to the current test contract
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (int256(swapAmount), -66.806655895621834199 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: 5598698009142142596565733951525, // 4993.613409332654
                tick: 85163,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    function testSwapBuyETHNotEnoughLiquidity() public pure {
        // PoolParams memory poolParams = PoolParams({
        //     wethBalance: 1 ether,
        //     usdcBalance: 5001 ether,
        //     tickCurrent: 85176,
        //     tickLower: 84222,
        //     tickUpper: 86129,
        //     liquidity: 1517882343751509868544,
        //     currentSqrtP: 5602277097478614198912276234240, // ≈ (1 ETH = 5000 USDC)
        //     shouldTransferInCallback: true,
        //     mintLiquidity: true
        // });

        // setupTestCase(poolParams);
    }
}
