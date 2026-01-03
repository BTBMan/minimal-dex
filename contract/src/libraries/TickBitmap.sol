// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/
error InvalidTick();

/* Interfaces ****/

/* Libraries *****/
import {BitMath} from "./BitMath.sol";

library TickBitmap {
    /**
     * @notice Get word position and bit position by tick
     */
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    /**
     * @notice Flip the tick
     */
    function flipTick(mapping(int16 word => uint256 tick) storage self, int24 tick, int24 tickSpacing) internal {
        if (tick % tickSpacing != 0) {
            revert InvalidTick();
        }

        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /**
     * @notice Get the next tick with liquidity within one word
     * @param self The mapping of word position to tick
     * @param tick The current tick
     * @param tickSpacing The tick spacing
     * @param lte Whether to find the next tick less than or equal to the current tick
     * @return nextTick The next tick with liquidity within one word
     * @return initialized Whether the next tick is initialized
     */
    function nextInitializedTickWithinOneWord(
        mapping(int16 word => uint256 tick) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 nextTick, bool initialized) {
        int24 compressed = tick / tickSpacing;

        if (lte) {
            // Selling token x, Search to the right
            (int16 wordPos, uint8 bitPos) = position(compressed);
            uint256 mask = 1 << bitPos - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            initialized = masked != 0;
            nextTick = initialized
                ? compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : compressed - int24(uint24(bitPos)) * tickSpacing;
        } else {
            // Buying token x, Search to the left
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;
            initialized = masked != 0;
            nextTick = initialized
                ? compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : compressed + 1 + int24(uint24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }
}
