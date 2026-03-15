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

    // Test buy ETH ============================
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

    function testBuyETHTwoEqualPriceRanges() public {
        LiquidityRange memory range = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range;
        liquidity[1] = range;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint128 liquidityAmount = liquidity[0].amount + liquidity[1].amount;
        uint256 swapAmount = 42 ether;

        // Mint and Approve some USDC tokens to the current test contract
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-0.008398498495503179 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: liquidityAmount,
                sqrtPriceX96: 5603332038489348602474524844738, // 5001.883234831316
                tick: 85179,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range.tickLower,
                        initialized: true,
                        liquidityGross: liquidityAmount,
                        liquidityNet: int128(liquidityAmount)
                    }),
                    ExpectedTickShort({
                        tick: range.tickUpper,
                        initialized: true,
                        liquidityGross: liquidityAmount,
                        liquidityNet: -int128(liquidityAmount)
                    })
                ]
            })
        );
    }

    function testBuyETHTwoConsecutivePriceRanges() public {
        (LiquidityRange memory range1, LiquidityRange memory range2) = (
            liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000), liquidityRange(5500, 6250, 1 ether, 5000 ether, 5000)
        );
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range1;
        liquidity[1] = range2;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 10000 ether;

        // Mint and Approve some USDC tokens to the current test contract
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-1.81912040370638959 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: range2.amount,
                sqrtPriceX96: 6194331388292842240173903498830, // 6112.652457372715
                tick: 87185,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range2.tickLower,
                        initialized: true,
                        liquidityGross: range1.amount + range2.amount,
                        liquidityNet: -int128(range1.amount - range2.amount)
                    }),
                    ExpectedTickShort({
                        tick: range2.tickUpper,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: -int128(range2.amount)
                    })
                ]
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickLower,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: int128(range1.amount)
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickUpper,
                initialized: true,
                liquidityGross: range1.amount + range2.amount,
                liquidityNet: -int128(range1.amount - range2.amount)
            })
        );
    }

    function testBuyETHPartiallyOverlappingPriceRanges() public {
        (LiquidityRange memory range1, LiquidityRange memory range2) = (
            liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000), liquidityRange(5001, 6250, 1 ether, 5000 ether, 5000)
        );
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range1;
        liquidity[1] = range2;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 10000 ether;

        // Mint and Approve some USDC tokens to the current test contract
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-1.862719660691831839 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: range2.amount,
                sqrtPriceX96: 6172233564764672077672517253553, // 6069.117370400689
                tick: 87114,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range2.tickLower,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: int128(range2.amount)
                    }),
                    ExpectedTickShort({
                        tick: range2.tickUpper,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: -int128(range2.amount)
                    })
                ]
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickLower,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: int128(range1.amount)
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickUpper,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: -int128(range1.amount)
            })
        );
    }

    // Test buy USDC =====================================
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

    function testBuyUSDCTwoEqualPriceRanges() public {
        LiquidityRange memory range = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range;
        liquidity[1] = range;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint128 liquidityAmount = liquidity[0].amount + liquidity[1].amount;
        uint256 swapAmount = 0.01337 ether;

        // Mint and Approve some ETH tokens to the current test contract
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (int256(swapAmount), -66.827684819295968855 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: liquidityAmount,
                sqrtPriceX96: 5600460327455047336528300624435, // 4996.757612287727
                tick: 85169,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range.tickLower,
                        initialized: true,
                        liquidityGross: liquidityAmount,
                        liquidityNet: int128(liquidityAmount)
                    }),
                    ExpectedTickShort({
                        tick: range.tickUpper,
                        initialized: true,
                        liquidityGross: liquidityAmount,
                        liquidityNet: -int128(liquidityAmount)
                    })
                ]
            })
        );
    }

    function testBuyUSDCTwoConsecutivePriceRanges() public {
        (LiquidityRange memory range1, LiquidityRange memory range2) = (
            liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000), liquidityRange(4000, 4540, 1 ether, 5000 ether, 5000)
        );
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range1;
        liquidity[1] = range2;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 2 ether;

        // Mint and Approve some ETH tokens to the current test contract
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (int256(swapAmount), -9098.355274825336550283 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: range2.amount,
                sqrtPriceX96: 5069757813637094491011532037516, // 4094.635609303384
                tick: 83178,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range2.tickLower,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: int128(range2.amount)
                    }),
                    ExpectedTickShort({
                        tick: range2.tickUpper,
                        initialized: true,
                        liquidityGross: range1.amount + range2.amount,
                        liquidityNet: int128(range1.amount - range2.amount)
                    })
                ]
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickLower,
                initialized: true,
                liquidityGross: range1.amount + range2.amount,
                liquidityNet: int128(range1.amount - range2.amount)
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickUpper,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: -int128(range1.amount)
            })
        );
    }

    function testBuyUSDCPartiallyOverlappingPriceRanges() public {
        (LiquidityRange memory range1, LiquidityRange memory range2) = (
            liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000), liquidityRange(4000, 4999, 1 ether, 5000 ether, 5000)
        );
        LiquidityRange[] memory liquidity = new LiquidityRange[](2);
        liquidity[0] = range1;
        liquidity[1] = range2;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 2 ether,
            usdcBalance: 10000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        uint256 swapAmount = 2 ether;

        // Mint and Approve some ETH tokens to the current test contract
        token0.mint(address(this), swapAmount);
        token0.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, abi.encode(token0, token1, address(this)));

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (int256(swapAmount), -9318.695291351037641952 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [token0, token1],
                liquidity: range2.amount,
                sqrtPriceX96: 5091197434700471409059068614113, // 4129.340643465598
                tick: 83262,
                fees: [uint256(0), 0],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: [
                    ExpectedTickShort({
                        tick: range2.tickLower,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: int128(range2.amount)
                    }),
                    ExpectedTickShort({
                        tick: range2.tickUpper,
                        initialized: true,
                        liquidityGross: range2.amount,
                        liquidityNet: -int128(range2.amount)
                    })
                ]
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickLower,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: int128(range1.amount)
            })
        );

        assertTick(
            ExpectedTick({
                pool: pool,
                tick: range1.tickUpper,
                initialized: true,
                liquidityGross: range1.amount,
                liquidityNet: -int128(range1.amount)
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
