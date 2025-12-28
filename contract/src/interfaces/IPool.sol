// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IPool {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }
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

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    error SwapFailed();

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    function token0() external view returns (address);
    function token1() external view returns (address);

    function positions(bytes32 positionKey) external view returns (uint128 liquidity);
    function ticks(int24 tick) external view returns (bool initialized, uint128 liquidity);
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick);
    function liquidity() external view returns (uint128 liquidity);

    function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);
}
