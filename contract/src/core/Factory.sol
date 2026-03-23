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
    mapping(uint24 fee => int24 tickSpacing) public feeAmountTickSpacing; // 1000 fee = 0.1%, 100 fee = 0.01%, 10 fee = 0.001%, 1 fee = 0.0001%
    mapping(address token0 => mapping(address token1 => mapping(uint24 fee => address pool))) public pools;

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
        // Set the initialization of fee
        feeAmountTickSpacing[1] = 1;
        feeAmountTickSpacing[500] = 10;
        feeAmountTickSpacing[3000] = 60;
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
    function getPool(address tokenA, address tokenB, uint24 fee) public view override returns (address pool) {
        if (tokenA == tokenB) {
            revert TokensMustBeDifferent();
        }

        if (tokenA == address(0) || tokenB == address(0)) {
            revert TokenCannotBeZero();
        }

        pool = pools[tokenA][tokenB][fee];
    }

    function createPool(address tokenA, address tokenB, uint24 fee) public returns (address pool) {
        if (tokenA == tokenB) {
            revert TokensMustBeDifferent();
        }

        int24 tickSpacing = feeAmountTickSpacing[fee];
        if (tickSpacing == 0) {
            revert UnsupportedFee();
        }

        // Ensure the tokens' order
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        // Ensure the token0 cannot be zero address
        // Check token1 is unnecessary because token0 is the smaller one
        if (token0 == address(0)) {
            revert Token0CannotBeZero();
        }

        // Ensure the pool cannot be created
        if (pools[token0][token1][fee] != address(0)) {
            revert PoolAlreadyExists();
        }

        pool = deploy(address(this), token0, token1, fee, tickSpacing);

        pools[token0][token1][fee] = pool;
        pools[token1][token0][fee] = pool;

        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
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
