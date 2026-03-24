// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IPool {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }

    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }
    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    event Flash(address indexed recipient, uint256 amount0, uint256 amount1);
    event Initialize(uint160 sqrtPriceX96, int24 tick);
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address indexed recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint256 amount0,
        uint256 amount1
    );

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();
    error SwapFailed();
    error NotEnoughLiquidity();
    error InvalidSqrtPriceLimitX96();
    error FlashLoanNotPaid();
    error AlreadyInitialized();

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    function token0() external view returns (address);
    function token1() external view returns (address);

    function positions(bytes32 positionKey)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function ticks(int24 tick)
        external
        view
        returns (
            bool initialized,
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128
        );
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick);
    function liquidity() external view returns (uint128 liquidity);

    function initialize(uint160 sqrtPriceX96) external;
    function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1);
    function collect(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Requested,
        uint256 amount1Requested
    ) external returns (uint256 amount0, uint256 amount1);
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);
    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    function flash(uint256 amount0, uint256 amount1, bytes calldata data) external;
}
