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
        setupTestCase(poolParams);

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidity[0].amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                userBalances: [1 ether - expectedAmount0, 5000 ether - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                ticks: rangeToTicks(liquidity[0]),
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );
    }

    function testFlash() public {
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 6500 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        setupTestCase(poolParams);

        vm.expectEmit(true, true, true, false);
        pool.flash(0.1 ether, 1000 ether, abi.encodePacked(uint256(0.1 ether), uint256(1000 ether)));

        assert(flashCallbackCalled);
    }

    function testBurn() public {
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
        setupTestCase(poolParams);

        (uint256 burnAmount0, uint256 burnAmount1) =
            pool.burn(liquidity[0].tickLower, liquidity[0].tickUpper, liquidity[0].amount);

        uint256 expectedAmount0 = 0.987877509829196392 ether;
        uint256 expectedAmount1 = 4999.999999999999999997 ether;

        assertEq(burnAmount0, expectedAmount0);
        assertEq(burnAmount1, expectedAmount1);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: 0,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(expectedAmount0), uint128(expectedAmount1)]
                }),
                userBalances: [1 ether - expectedAmount0 - 1, 5000 ether - expectedAmount1 - 1],
                poolBalances: [expectedAmount0 + 1, expectedAmount1 + 1],
                ticks: [
                    ExpectedTickShort({
                        tick: liquidity[0].tickLower, initialized: true, liquidityGross: 0, liquidityNet: 0
                    }),
                    ExpectedTickShort({
                        tick: liquidity[0].tickUpper, initialized: true, liquidityGross: 0, liquidityNet: 0
                    })
                ],
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );
    }

    function testCollect() public {
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            false,
            swapAmount,
            sqrtP(5004),
            encodeCallbackData(address(weth), address(usdc), address(this))
        );

        pool.burn(liquidity[0].tickLower, liquidity[0].tickUpper, liquidity[0].amount);

        bytes32 positionKey = keccak256(abi.encodePacked(address(this), liquidity[0].tickLower, liquidity[0].tickUpper));
        (,,, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(positionKey);

        assertEq(tokensOwed0, uint256(int256(poolBalance0) + amount0));
        assertEq(tokensOwed1, uint256(int256(poolBalance1) + amount1 - 2));

        (uint128 amountCollect0, uint128 amountCollect1) =
            pool.collect(address(this), liquidity[0].tickLower, liquidity[0].tickUpper, tokensOwed0, tokensOwed1);

        assertEq(amountCollect0, tokensOwed0);
        assertEq(amountCollect1, tokensOwed1);

        assertEq(weth.balanceOf(address(pool)), uint256(int256(poolBalance0) + amount0) - uint256(amountCollect0));
        assertEq(usdc.balanceOf(address(pool)), uint256(int256(poolBalance1) + amount1) - uint256(amountCollect1));

        (,,, tokensOwed0, tokensOwed1) = pool.positions(positionKey);
        assertEq(tokensOwed0, 0);
        assertEq(tokensOwed1, 0);
    }
}
