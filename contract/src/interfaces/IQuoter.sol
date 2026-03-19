// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IQuoter {
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}
