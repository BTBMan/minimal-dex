// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IPoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        int24 tickSpacing;
    }

    function parameters() external view returns (address factory, address token0, address token1, int24 tickSpacing);
}
