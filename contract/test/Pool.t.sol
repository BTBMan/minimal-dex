// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Pool} from "../src/core/Pool.sol";
import {TestUtils} from "./utils/TestUtils.sol";

/* Interfaces ****/

/* Libraries *****/

contract PoolTest is Test, TestUtils {
    function setUp() public override {
        super.setUp();
    }

    function testMintSuccess() public {
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

        // Balance
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        assertEq(poolBalance0, expectedAmount0, "Incorrect token0 deposited amount");
        assertEq(poolBalance1, expectedAmount1, "Incorrect token1 deposited amount");

        assertEq(token0.balanceOf(address(pool)), expectedAmount0);
        assertEq(token1.balanceOf(address(pool)), expectedAmount1);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [1 ether - expectedAmount0, 5000 ether - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    // function testSwapBuyETH() public {
    //     PoolParams memory poolParams = PoolParams({
    //         wethBalance: 1 ether,
    //         usdcBalance: 5001 ether,
    //         tickCurrent: 85176,
    //         tickLower: 84222,
    //         tickUpper: 86129,
    //         liquidity: 1517882343751509868544,
    //         currentSqrtP: 5602277097478614198912276234240, // ≈ (1 ETH = 5000 USDC)
    //         shouldTransferInCallback: true,
    //         mintLiquidity: true
    //     });

    //     // Balance
    //     (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

    //     uint256 swapAmount = 42 ether;

    //     // Mint 42 USDC to the test contract
    //     token1.mint(address(this), swapAmount);

    //     // Approve tokens to the current test contract
    //     token1.approve(address(this), swapAmount);

    //     int256 userBalance0Before = int256(token0.balanceOf(address(this)));
    //     int256 userBalance1Before = int256(token1.balanceOf(address(this)));

    //     // Swap
    //     (int256 amount0Delta, int256 amount1Delta) =
    //         pool.swap(address(this), false, swapAmount, abi.encode(token0, token1, address(this)));

    //     // Check swap amount
    //     assertEq(amount0Delta, -0.008396714242162445 ether);
    //     assertEq(amount1Delta, int256(swapAmount));

    //     // Check user(the test contract) balance
    //     assertEq(token0.balanceOf(address(this)), uint256(userBalance0Before - amount0Delta));
    //     assertEq(token1.balanceOf(address(this)), uint256(userBalance1Before - amount1Delta));

    //     // Check pool balance
    //     assertEq(token0.balanceOf((address(pool))), uint256(int256(poolBalance0) + amount0Delta));
    //     assertEq(token1.balanceOf((address(pool))), uint256(int256(poolBalance1) + amount1Delta));

    //     // Check sqrtPrice, tick and liquidity
    //     (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
    //     assertEq(sqrtPriceX96, 5604469350942327889444743441197);
    //     assertEq(tick, 85184);
    //     assertEq(pool.liquidity(), 1517882343751509868544);
    // }
}
