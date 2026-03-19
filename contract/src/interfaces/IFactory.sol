// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IFactory {
    event PoolCreated(address indexed token0, address indexed token1, int24 indexed tickSpacing, address pool);

    error TokensMustBeDifferent();
    error UnsupportedTickSpacing();
    error Token0CannotBeZero();
    error PoolAlreadyExists();
    error TokenCannotBeZero();

    function getPool(address tokenA, address tokenB, int24 tickSpacing) external returns (address pool);
    function createPool(address tokenA, address tokenB, int24 tickSpacing) external returns (address pool);
}
