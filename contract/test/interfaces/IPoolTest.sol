// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IPoolTest {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////
    struct PoolParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        int24 tickCurrent;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool shouldTransferInCallback;
        bool mintLiquidity;
    }

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////
}
