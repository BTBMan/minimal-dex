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

    function testBuyETHOnePriceRange() public pure {
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
