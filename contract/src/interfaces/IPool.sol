// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IPool {
    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();

    function token0() external view returns (address);
    function token1() external view returns (address);

    function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);
}
