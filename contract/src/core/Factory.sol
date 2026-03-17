// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {PoolDeployer} from "./PoolDeployer.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {IFactory} from "../interfaces/IFactory.sol";

/* Libraries *****/

/**
 * @title Factory
 * @author BTBMan
 * @notice This is a contract
 */
contract Factory is IFactory, PoolDeployer {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    mapping(int24 tickSpacing => bool) public tickSpacings;
    mapping(address token0 => mapping(address token1 => mapping(int24 tickSpacing => address pool))) public pools;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor() {
        // Set the initialization of tick spacing
        tickSpacings[1] = true;
        tickSpacings[10] = true;
        tickSpacings[60] = true;
    }

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////

    // External view  //////////////////

    // External pure  //////////////////

    ////////////////////////////////////
    // Public functions               //
    ////////////////////////////////////
    function createPool(address tokenA, address tokenB, int24 tickSpacing) public returns (address pool) {
        if (tokenA == tokenB) {
            revert TokensMustBeDifferent();
        }

        if (!tickSpacings[tickSpacing]) {
            revert UnsupportedTickSpacing();
        }

        // Ensure the tokens' order
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Ensure the token0 cannot be zero address
        // Check token1 is unnecessary because token0 is the smaller one
        if (token0 == address(0)) {
            revert Token0CannotBeZero();
        }

        // Ensure the pool cannot be created
        if (pools[token0][token1][tickSpacing] != address(0)) {
            revert PoolAlreadyExists();
        }

        pool = deploy(address(this), token0, token1, tickSpacing);

        pools[token0][token1][tickSpacing] = pool;
        pools[token1][token0][tickSpacing] = pool;

        emit PoolCreated(token0, token1, tickSpacing, pool);
    }

    // Public view  ////////////////////

    // Public pure  ////////////////////

    ////////////////////////////////////
    // Internal functions             //
    ////////////////////////////////////

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
