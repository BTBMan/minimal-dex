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
    bytes callbackData;

    function setUp() public override {
        super.setUp();
        callbackData = encodeCallbackData(address(weth), address(usdc), address(this));
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, sqrtP(5004), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-0.008396829291658311 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: 5604440319184809477873515789008, // 5003.862071285904
                tick: 85183,
                fees: [uint256(0), 9520077723740638453671021421607],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidity[0].amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, sqrtP(5002), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-0.008398490098665821 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidityAmount,
                sqrtPriceX96: 5603332037381065690447825392348, // 5001.883232852671
                tick: 85179,
                fees: [uint256(0), 4760038861870319226835510710803],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidityAmount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, sqrtP(6113), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-1.819118767755198632 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: range2.amount,
                sqrtPriceX96: 6194330727015523656888479711743, // 6112.651152257456
                tick: 87185,
                fees: [uint256(0), 2543082621143305072629880308303040],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range1.tickLower, range1.tickUpper],
                    liquidity: range1.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: [
                    ExpectedTickShort({
                        tick: range1.tickLower,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: int128(range1.amount)
                    }),
                    ExpectedTickShort({
                        tick: range1.tickUpper,
                        initialized: true,
                        liquidityGross: range1.amount + range2.amount,
                        liquidityNet: -int128(range1.amount - range2.amount)
                    })
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range2.tickLower, range2.tickUpper],
                    liquidity: range2.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, sqrtP(6070), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (-1.862718013005470885 ether, int256(swapAmount));

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: range2.amount,
                sqrtPriceX96: 6172232383251629775917976287024, // 6069.115046852635
                tick: 87114,
                fees: [uint256(0), 2448170862469857064377406228021655],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range1.tickLower, range1.tickUpper],
                    liquidity: range1.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: [
                    ExpectedTickShort({
                        tick: range1.tickLower,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: int128(range1.amount)
                    }),
                    ExpectedTickShort({
                        tick: range1.tickUpper,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: -int128(range1.amount)
                    })
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range2.tickLower, range2.tickUpper],
                    liquidity: range2.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
    }

    function testBuyETHSlippageInterruption() public {
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
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), false, swapAmount, sqrtP(5003), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (-0.006367981248889227 ether, 31.848884516117098735 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: sqrtP(5003),
                tick: tick(5003),
                fees: [uint256(0), 7219139428759121781392346972620],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidity[0].amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    function testSwapBuyETHNotEnoughLiquidity() public {
        LiquidityRange memory range = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = range;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        setupTestCase(poolParams);

        uint256 swapAmount = 5300 ether;

        // Mint and Approve some USDC tokens to the current test contract
        usdc.mint(address(this), swapAmount);
        usdc.approve(address(this), swapAmount);

        vm.expectRevert(encodeError("NotEnoughLiquidity()"));
        pool.swap(address(this), false, swapAmount, sqrtP(6000), callbackData);
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
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, sqrtP(4993), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (int256(swapAmount), -66.806589131010509403 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: 5598698012665670113678845821468, // 4993.613415618091
                tick: 85163,
                fees: [3030558075390769907751941819, uint256(0)],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidity[0].amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, sqrtP(4996), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) = (int256(swapAmount), -66.827618012646671539 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidityAmount,
                sqrtPriceX96: 5600460329217920380003911069891, // 4996.757615433415
                tick: 85169,
                fees: [1515279037695384953875970909, uint256(0)],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidityAmount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, sqrtP(4094), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (int256(swapAmount), -9098.347085553250996988 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: range2.amount,
                sqrtPriceX96: 5069758350327724923607021157406, // 4094.6364762294834
                tick: 83178,
                fees: [505432482968936265929098748173, uint256(0)],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range1.tickLower, range1.tickUpper],
                    liquidity: range1.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: [
                    ExpectedTickShort({
                        tick: range1.tickLower,
                        initialized: true,
                        liquidityGross: range1.amount + range2.amount,
                        liquidityNet: int128(range1.amount - range2.amount)
                    }),
                    ExpectedTickShort({
                        tick: range1.tickUpper,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: -int128(range1.amount)
                    })
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range2.tickLower, range2.tickUpper],
                    liquidity: range2.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, sqrtP(4129), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (int256(swapAmount), -9318.687032668167197844 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: range2.amount,
                sqrtPriceX96: 5091198410869847077109758442744, // 4129.342226958015
                tick: 83262,
                fees: [483038147031209432005321726421, uint256(0)],
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range1.tickLower, range1.tickUpper],
                    liquidity: range1.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: [
                    ExpectedTickShort({
                        tick: range1.tickLower,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: int128(range1.amount)
                    }),
                    ExpectedTickShort({
                        tick: range1.tickUpper,
                        initialized: true,
                        liquidityGross: range1.amount,
                        liquidityNet: -int128(range1.amount)
                    })
                ]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [range2.tickLower, range2.tickUpper],
                    liquidity: range2.amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
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
    }

    function testBuyUSDCSlippageInterruption() public {
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
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        int256 userBalance0Before = int256(weth.balanceOf(address(this)));
        int256 userBalance1Before = int256(usdc.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) =
            pool.swap(address(this), true, swapAmount, sqrtP(4994), callbackData);

        (int256 expectedAmount0Delta, int256 expectedAmount1Delta) =
            (0.012741707568980385 ether, -63.669049964153300768 ether);

        // Check swap amount
        assertEq(amount0Delta, expectedAmount0Delta);
        assertEq(amount1Delta, expectedAmount1Delta);

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [weth, usdc],
                liquidity: liquidity[0].amount,
                sqrtPriceX96: sqrtP(4994),
                tick: tick(4994),
                fees: [2888143961667961523286488321, uint256(0)],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity[0].tickLower, liquidity[0].tickUpper],
                    liquidity: liquidity[0].amount,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                userBalances: [uint256(userBalance0Before - amount0Delta), uint256(userBalance1Before - amount1Delta)],
                poolBalances: [
                    uint256(int256(poolBalance0) + amount0Delta), uint256(int256(poolBalance1) + amount1Delta)
                ],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    function testSwapBuyUSDCNotEnoughLiquidity() public {
        LiquidityRange memory range = liquidityRange(4540, 5500, 1 ether, 5000 ether, 5000);
        LiquidityRange[] memory liquidity = new LiquidityRange[](1);
        liquidity[0] = range;
        PoolParams memory poolParams = PoolParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            liquidity: liquidity,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });
        setupTestCase(poolParams);

        uint256 swapAmount = 2 ether;

        // Mint and Approve some ETH tokens to the current test contract
        weth.mint(address(this), swapAmount);
        weth.approve(address(this), swapAmount);

        vm.expectRevert(encodeError("NotEnoughLiquidity()"));
        pool.swap(address(this), true, swapAmount, sqrtP(4000), callbackData);
    }
}
