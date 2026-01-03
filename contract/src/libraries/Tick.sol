// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(mapping(int24 tick => Info) storage self, int24 tick, uint128 liquidityDelta)
        internal
        returns (bool flipped)
    {
        Info storage tickInfo = self[tick]; // Get current tick info

        uint128 liquidityBefore = tickInfo.liquidity;
        uint128 liquidityAfter = liquidityBefore + liquidityDelta;

        // liquidityBefore == 0 means this tick never initialized.
        // If it was initialized, we don't need to reassign.
        if (liquidityBefore == 0) {
            tickInfo.initialized = true;
        }

        tickInfo.liquidity = liquidityAfter; // Update current tick liquidity
        flipped = (liquidityBefore == 0) != (liquidityAfter == 0); // flipped if add liquidity to an empty tick or remove all liquidity from a non-empty tick
    }
}
