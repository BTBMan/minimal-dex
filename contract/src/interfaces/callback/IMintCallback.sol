// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IMintCallback {
    function mintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external;
}
