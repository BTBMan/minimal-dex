// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISwapRouter {
    struct SwapCallbackData {
        address token0;
        address token1;
        address payer;
    }

    struct ExactInputSingleParams {
        address pool;
        uint256 amountIn;
        bool zeroForOne;
    }

    function exactInput(address poolAddress, bytes calldata data) external;
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut);
    function exactOutput(address poolAddress, bytes calldata data) external;
    function exactOutputSingle(address poolAddress, bytes calldata data) external;
}
