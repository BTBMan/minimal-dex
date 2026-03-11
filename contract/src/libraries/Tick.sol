// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/
import {LiquidityMath} from "./LiquidityMath.sol";

library Tick {
    struct Info {
        bool initialized;
        // Total liquidity at tick
        uint128 liquidityGross;
        // Amount of liquidity added or subtracted when the tick is crossed
        int128 liquidityNet;
    }

    function update(mapping(int24 tick => Info) storage self, int24 tick, int128 liquidityDelta, bool upper)
        internal
        returns (bool flipped)
    {
        Info storage tickInfo = self[tick]; // Get current tick info

        uint128 liquidityBefore = tickInfo.liquidityGross;
        uint128 liquidityAfter = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);

        // liquidityBefore == 0 means this tick never initialized.
        // If it was initialized, we don't need to reassign.
        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        flipped = (liquidityBefore == 0) != (liquidityAfter == 0); // flipped if add liquidity to an empty tick or remove all liquidity from a non-empty tick
        tickInfo.liquidityGross = liquidityAfter; // Update current tick liquidity

        // If cross into tickLower from other tick range, means increase the liquidity
        // Otherwise, cross into tickUpper from other tick range, means decrease the liquidity
        tickInfo.liquidityNet = upper
            ? int128(int256(tickInfo.liquidityNet) - liquidityDelta)
            : int128(int256(tickInfo.liquidityNet) + liquidityDelta);
    }

    function cross(mapping(int24 tick => Info) storage self, int24 tick) internal view returns (int128 liquidityDelta) {
        Info storage tickInfo = self[tick]; // Get current tick info
        liquidityDelta = tickInfo.liquidityNet;
    }
}
