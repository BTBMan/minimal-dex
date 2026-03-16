// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IFlashCallback {
    function flashCallback(bytes calldata data) external;
}
