// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface INonfungiblePositionManager {
    struct MintCallbackData {
        address token0;
        address token1;
        address payer;
    }
    // struct MintParams {
    //   //
    // };
    // function createAndInitializePoolIfNecessary() external;
    function mint(address poolAddress, int24 tickLower, int24 tickUpper, uint128 liquidity, bytes calldata data)
        external;
}
