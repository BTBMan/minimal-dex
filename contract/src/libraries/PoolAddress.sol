// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "./../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/

library PoolAddress {
    /**
     * @notice Compute the pool address
     * @param factory The address of the factory contract
     * @param tokenA The address of the first token
     * @param tokenB The address of the second token
     * @param tickSpacing The tick spacing
     * @return address The address of the pool contract
     */
    function computeAddress(address factory, address token0, address token1, uint24 tickSpacing)
        internal
        returns (address pool)
    {
        // Ensure token0 less than token1
        require(token0 < token1);

        pool = keccak256(
            abi.encodePacked(
                "0xff",
                factory,
                keccak256(abi.encodePacked(token0, token1, tickSpacing)),
                keccak256(type(Pool).creationCode)
            )
        );
    }
}
