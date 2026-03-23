// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "./../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/

library PoolAddress {
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /**
     * @notice Returns PoolKey, with the ordered tokens
     */
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory poolKey) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        poolKey = PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /**
     * @notice Compute the pool address
     * @param factory The address of the factory contract
     * @param key The pool key
     * @return pool The address of the pool contract
     */
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        // Ensure token0 less than token1
        require(key.token0 < key.token1);

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            keccak256(type(Pool).creationCode)
                        )
                    )
                )
            )
        );
    }
}
