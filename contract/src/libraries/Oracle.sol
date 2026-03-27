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
        uint32 timestamp;
        // The cumulative of the tick
        int56 tickCumulative;
        // Whether the tick is initialized
        bool initialized;
    }

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
        self[0] = Observation({timestamp: time, tickCumulative: 0, initialized: true});

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
        if (timestamp == last.timestamp) return (index, cardinality);

        //
    }
}
