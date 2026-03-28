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

        // Update the observation of the new index
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
}
