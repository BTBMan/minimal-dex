// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IFactory {
    event PoolCreated(address indexed token0, address indexed token1, uint24 indexed tickSpacing, address pool);

    error TokensMustBeDifferent();
    error UnsupportedTickSpacing();
    error Token0CannotBeZero();
    error PoolAlreadyExists();

    function createPool(address tokenA, address tokenB, uint24 tickSpacing) external returns (address pool);
}
