// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/

library Oracle {
    struct Observation {
        // Block timestamp
        uint32 blockTimestamp;
        // The cumulative of the tick
        int56 tickCumulative;
        // Whether the tick is initialized
        bool initialized;
    }

    error NotZeroCardinality();
    error TooOldObservation();

    /**
     * @notice Initialize the observation
     * @param time The block timestamp
     * @return cardinality The number of the populated elements in the oracle array
     * @return cardinalityNext The new length of the oracle array
     */
    function initialize(Observation[65535] storage self, uint32 time)
        internal
        returns (uint16 cardinality, uint16 cardinalityNext)
    {
        self[0] = Observation({blockTimestamp: time, tickCumulative: 0, initialized: true});

        // Set cardinality and cardinalityNext to 1 when the pool is initialized
        cardinality = 1;
        cardinalityNext = 1;
    }

    /**
     * @notice Write the oracle observation to the array
     * @param index The index of the observation
     * @param timestamp The block timestamp
     * @param tick The tick of the sqrtPriceX96
     * @param cardinality The number of the populated elements in the oracle array
     * @param cardinalityNext The new length of the oracle array
     * @return indexUpdated The new index of the most recently written element in the oracle array
     * @return cardinalityUpdated The new cardinality of the oracle array
     */
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 timestamp,
        int24 tick,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // Return if already written in the same block
        if (timestamp == last.blockTimestamp) return (index, cardinality);

        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            // When the length of the populated elements is less than the maximum length of the oracle array
            // And the index of the most recently written element in the array is the last element of the cardinality
            // We need to update the cardinality to the new next cardinality
            cardinalityUpdated = cardinalityNext;
        } else {
            // Otherwise, that means the cardinality is equal or greater than the maximum length of the oracle array
            // Or the populated elements includes the old observations and the new observations
            // Make the cardinality the same as the previous cardinality
            cardinalityUpdated = cardinality;
        }

        // Update the most recently written observation index
        // Modulo operation is used to make sure the index is always inside the range of the maximum length of the array
        indexUpdated = (index + 1) % cardinalityUpdated;

        // Update the observation at the new index
        self[indexUpdated] = transform(last, timestamp, tick);
    }

    /**
     * @notice Transform the observation to the new observation
     * @param last The last observation
     * @param blockTimestamp The block timestamp
     * @param tick The tick of the sqrtPriceX96
     * @return newObservation The new observation after transformation
     */
    function transform(Observation memory last, uint32 blockTimestamp, int24 tick)
        internal
        pure
        returns (Observation memory)
    {
        // Get the seconds elapsed since the last observation
        uint32 delta = blockTimestamp - last.blockTimestamp;

        return Observation({
            blockTimestamp: blockTimestamp,
            tickCumulative: last.tickCumulative + int56(tick) * int56(int32(delta)),
            initialized: true
        });
    }

    /**
     * @notice Grow the oracle array
     * @param self The oracle array
     * @param current The current cardinality
     * @param next The new cardinality
     * @return next The new cardinality
     */
    function grow(Observation[65535] storage self, uint16 current, uint16 next) internal returns (uint16) {
        if (current <= 0) {
            revert NotZeroCardinality();
        }

        if (next <= current) {
            return current;
        }

        // Fill the array
        for (uint16 i = current; i < next; i++) {
            self[i].blockTimestamp = 1;
        }

        return next;
    }

    /**
     * @notice Time comparator(Less Than or Equal to the current time)
     * @dev a <= b <= time
     */
    function lte(uint32 time, uint32 a, uint32 b) internal pure returns (bool) {
        if (a <= time && b <= time) return a <= b;

        // If a and b greater than the current time
        // Means a and b are in the next 32-bit cycle(overflowed)
        // We need to unify the cycle to compare a and b
        uint256 aAdjusted = a > time ? a : a + 2 ** 32;
        uint256 bAdjusted = b > time ? b : b + 2 ** 32;

        return aAdjusted <= bAdjusted;
    }

    /**
     * @notice Get the observation beforeOrAt and atOrAfter a given target
     * @param time Usually, the current block timestamp
     * @param target A timestamp which we want to query the observation
     * @param index The index of the most recently written observation in array
     * @param cardinality The number of the populated elements in array
     * @return beforeOrAt The each tick cumulative of each secondsAg
     * @return atOrAfter The each tick cumulative of each secondsAg
     */
    function binarySearch(Observation[65535] storage self, uint32 time, uint32 target, uint16 index, uint16 cardinality)
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        //   [1, 2, 3, 4, 5]
        //    ↑           ↑
        // oldest[0]   index[4]
        // ----------------------
        //   [6,         2, 3, 4, 5]
        //    ↑          ↑
        // index[0]   oldest[1]
        uint256 l = (index + 1) % cardinality; // The index of the oldest observation(left side)
        //   [6, 7, 8,   4, 5]+[v, v, v]
        //          ↑    ↑            ↑
        //          ↑ oldest[3]    newest[3+5-1=7] [7%5=2]
        //          ↑                                   ↓
        //          ↑___________________________________↓
        // --------With uninitialize---------------
        //   [1, 2, 3,   4, 5,      6(un), 7(un)]+[v, v, v, v, v]
        //                  ↑       ↑                          ↑
        //              newest[4] oldest[5]                 newest[5+7-1=11] [11%7=4]
        //                  ↑                                                      ↓
        //                  ↑______________________________________________________↓
        uint256 r = l + cardinality - 1; // The index of the newest observation(right side)
        uint256 i; // The middle index

        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // The uninitialized observation is always start from the left to the right
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);
            bool targetBeforeOrAt = lte(time, target, atOrAfter.blockTimestamp);

            // If the target is between beforeOrAt and atOrAfter, break the loop
            if (targetAtOrAfter && targetBeforeOrAt) {
                break;
            }

            if (!targetAtOrAfter) {
                r = i - 1;
            } else {
                l = i + 1;
            }
        }
    }

    /**
     * @notice Get the observation beforeOrAt and atOrAfter a given target
     * @param time Usually, the current block timestamp
     * @param target A timestamp which we want to query the observation
     * @param tick Usually, the current tick
     * @param index The index of the most recently written observation in array
     * @param cardinality The number of the populated elements in array
     * @return beforeOrAt The each tick cumulative of each secondsAg
     * @return atOrAfter The each tick cumulative of each secondsAg
     */
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // Optimistically set the newest observation to beforeOrAt
        beforeOrAt = self[index];

        // If target is equal or greater than the newest observation
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // If target is equal to the newest observation
                // Just return the newest observation as the beforeOrAt, ignore the atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // If target is greater than the newest observation
                // We should transform the time that between the newest observation and the target
                return (beforeOrAt, transform(beforeOrAt, target, tick));
            }
        }

        // Set beforeOrAt to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) {
            // If beforeOrAt is not initialized, means the rest of the elements start from beforeOrAt are not initialized
            // So, the oldest observation is the first element
            beforeOrAt = self[0];
        }

        // Ensure the oldest observation than the target
        if (!lte(time, beforeOrAt.blockTimestamp, target)) {
            revert TooOldObservation();
        }

        return binarySearch(self, time, target, index, cardinality);
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56) {
        // secondsAgo == 0 means search the observation of the current time
        if (secondsAgo == 0) {
            // Find the last observation
            Observation memory last = self[index];

            // If the last.blockTimestamp != current time means the current time greater than the last block timestamp
            // It can not be less than last block timestamp
            if (last.blockTimestamp != time) {
                // Update the `last` to the observation of the latest block timestamp
                last = transform(last, time, tick);
            }

            return last.tickCumulative;
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            return beforeOrAt.tickCumulative;
        } else if (target == atOrAfter.blockTimestamp) {
            return atOrAfter.tickCumulative;
        } else {
            uint56 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint56 targetDelta = target - beforeOrAt.blockTimestamp;

            return beforeOrAt.tickCumulative
                + ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / int56(observationTimeDelta))
                * int56(targetDelta);
        }
    }

    /**
     * @notice Return each cumulation of the each seconds ago
     * @param time Usually, the current block timestamp
     * @param secondsAgos The time we want to query the tick cumulation (in second)
     * @param tick Usually, the current tick
     * @param index The index of the most recently written observation in array
     * @param cardinality The number of the populated elements in array
     * @return tickCumulatives The each tick cumulative of each secondsAgo
     */
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56[] memory tickCumulatives) {
        tickCumulatives = new int56[](secondsAgos.length);

        for (uint256 i = 0; i < secondsAgos.length; i++) {
            tickCumulatives[i] = observeSingle(self, time, secondsAgos[i], tick, index, cardinality);
        }
    }
}
