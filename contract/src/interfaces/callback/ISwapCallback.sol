// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface ISwapCallback {
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}
