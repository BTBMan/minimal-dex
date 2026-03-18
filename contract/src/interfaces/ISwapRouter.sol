// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISwapRouter {
    struct SwapCallbackData {
        // Swap path
        bytes path;
        address payer;
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        int24 tickSpacing;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        // Token amountIn recipient
        address recipient;
        uint256 amountIn;
        // The minimum token amountOut we desired
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        int24 tickSpacing;
        uint256 amountOut;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        // Token amountOut recipient
        address recipient;
        uint256 amountOut;
        // The maximum token amountIn we desired
        uint256 amountInMaximum;
    }

    error TooLittleReceived(uint256 amountOut);
    error InsufficientAmountDelta();

    function factory() external returns (address factory);
    function exactInput(ExactInputParams memory params) external returns (uint256 amountOut);
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut);
    function exactOutput(ExactOutputParams memory params) external returns (uint256 amountIn);
    function exactOutputSingle(ExactOutputSingleParams memory params) external returns (uint256 amountIn);
}
