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
                userBalances: [1 ether - expectedAmount0, 5000 ether - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                ticks: rangeToTicks(liquidity[0])
            })
        );
    }

    function testFlash() public {
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

        vm.expectEmit(true, true, true, false);
        pool.flash(0.1 ether, 1000 ether, abi.encodePacked(uint256(0.1 ether), uint256(1000 ether)));

        assert(flashCallbackCalled);
    }
}
