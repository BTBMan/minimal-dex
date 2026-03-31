// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        // The NFT token recipient
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

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        // The amount out token recipient
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct Position {
        address pool;
        int24 tickLower;
        int24 tickUpper;
    }

    error SlippageCheckFailed(uint256 amount0, uint256 amount1);
    error PositionDoesNotExist();
    error InsufficientLiquidity();
    error NotAuthorized();
    error NotCleared();

    event IncreaseLiquidity(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event DecreaseLiquidity(uint256 indexed tokenId, uint256 amount0, uint256 amount1);
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    function createAndInitializePoolIfNecessary(address tokenA, address tokenB, uint24 fee, uint160 sqrtPriceX96)
        external
        returns (address pool);
    function mint(MintParams calldata params)
        external
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}
