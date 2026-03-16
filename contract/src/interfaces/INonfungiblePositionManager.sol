// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface INonfungiblePositionManager {
    struct MintCallbackData {
        address token0;
        address token1;
        address payer;
    }

    struct MintParams {
        address token0;
        address token1;
        address poolAddress;
        // The LP token recipient
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        // token 0 amount that user desired to provide
        uint256 amount0Desired;
        // token 1 amount that user desired to provide
        uint256 amount1Desired;
        // token 0 minimal amount that user desired to provide
        uint256 amount0Min;
        // token 1 minimal amount that user desired to provide
        uint256 amount1Min;
    }

    error SlippageCheckFailed(uint256 amount0, uint256 amount1);

    // function createAndInitializePoolIfNecessary() external;
    function mint(MintParams calldata params) external returns (uint256 amount0, uint256 amount1);
}
