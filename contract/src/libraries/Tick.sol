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
        // Track fee growth on the outside of this tick
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
    }

    /**
     * @notice Get all fees inside the tick lower and tick upper
     */
    function getFeeGrowthInside(
        mapping(int24 tick => Info) storage self,
        int24 _tickLower,
        int24 _tickUpper,
        int24 currentTick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        Info storage lower = self[_tickLower];
        Info storage upper = self[_tickUpper];

        // Calculate the fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (currentTick >= _tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            // Remove the inside fee
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // Calculate the fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (currentTick < _tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            // Remove the inside fee
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthAbove0X128 - feeGrowthBelow0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthAbove1X128 - feeGrowthBelow1X128;
    }

    function update(
        mapping(int24 tick => Info) storage self,
        int24 tick,
        int24 currentTick,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper
    ) internal returns (bool flipped) {
        Info storage info = self[tick]; // Get current tick info

        uint128 liquidityBefore = info.liquidityGross;
        uint128 liquidityAfter = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);

        // liquidityBefore == 0 means this tick never initialized.
        // If it was initialized, we don't need to reassign.
        if (liquidityBefore == 0) {
            // By convention, Before a new tick will be initialized, we assume that all fee growth were collected below the tick
            if (tick <= currentTick) {
                info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
            }

            info.initialized = true;
        }

        flipped = (liquidityBefore == 0) != (liquidityAfter == 0); // flipped if add liquidity to an empty tick or remove all liquidity from a non-empty tick
        info.liquidityGross = liquidityAfter; // Update current tick liquidity

        // If cross into tickLower from other tick range, means increase the liquidity
        // Otherwise, cross into tickUpper from other tick range, means decrease the liquidity
        info.liquidityNet = upper
            ? int128(int256(info.liquidityNet) - liquidityDelta)
            : int128(int256(info.liquidityNet) + liquidityDelta);
    }

    function cross(
        mapping(int24 tick => Info) storage self,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal returns (int128 liquidityDelta) {
        Info storage info = self[tick]; // Get current tick info

        // Calculate the fee growth outside of this tick
        info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
        info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;

        liquidityDelta = info.liquidityNet;
    }
}
