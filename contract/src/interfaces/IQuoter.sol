// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IQuoter {
    struct SwapCallbackData {
        // address token0;
        // address token1;
        // address payer;
        address pool;
    }

    function quote(address pool, uint256 amountIn, uint160 sqrtPriceLimitX96, bool zeroForOne)
        external
        returns (uint256 amountOut);
    // function quoteExactInput(address poolAddress, bytes calldata data) external;
    // function quoteExactInputSingle(address pool, uint256 amountIn, bool zeroForOne) external returns (uint256 amountOut);
    // function quoteExactOutput(address poolAddress, bytes calldata data) external;
    // function quoteExactOutputSingle(address poolAddress, bytes calldata data) external;
}
