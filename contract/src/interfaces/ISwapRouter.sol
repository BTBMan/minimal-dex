// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISwapRouter {
    struct SwapCallbackData {
        address token0;
        address token1;
        address payer;
    }

    function swap(address poolAddress, bytes calldata data) external;
}
