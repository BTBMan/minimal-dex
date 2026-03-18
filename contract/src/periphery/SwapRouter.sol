// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {ISwapRouter} from "../interfaces/ISwapRouter.sol";
import {ISwapCallback} from "../interfaces/callback/ISwapCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "../interfaces/IPool.sol";

/* Libraries *****/
import {Path} from "../libraries/Path.sol";
import {PoolAddress} from "../libraries/PoolAddress.sol";
import {TickMath} from "../libraries/TickMath.sol";

/**
 * @title SwapRouter
 * @author BTBMan
 * @notice This is a contract
 */
contract SwapRouter is ISwapRouter, ISwapCallback {
    using Path for bytes;
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    // The address of the factory contract
    address public immutable factory;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor(address _factory) {
        factory = _factory;
    }

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert InsufficientAmountDelta();
        }

        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        (address tokenIn, address tokenOut,) = data.path.decodeFirstPool();

        // Determine the swap direction
        bool zeroForOne = tokenIn < tokenOut;

        int256 amount = zeroForOne ? amount0Delta : amount1Delta;

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (data.payer == address(this)) {
            // Means has multiple pools
            IERC20(tokenIn).transfer(msg.sender, uint256(amount));
        } else {
            IERC20(tokenIn).transferFrom(data.payer, msg.sender, uint256(amount));
        }
    }

    /**
     * @notice Get pool address by given tokenA, tokenB and tickSpacing
     */
    function getPool(address tokenA, address tokenB, int24 tickSpacing) private view returns (IPool pool) {
        pool = IPool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, tickSpacing)));
    }

    /**
     * @notice Performs a single exact input swap
     */
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // Extract the first pool parameters
        (address tokenIn, address tokenOut, int24 tickSpacing) = data.path.decodeFirstPool();

        // Determine the swap direction
        bool zeroForOne = tokenIn < tokenOut;

        // Execute the swap function
        (int256 amount0, int256 amount1) = getPool(tokenIn, tokenOut, tickSpacing)
            .swap(
                recipient,
                zeroForOne,
                amountIn,
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                (abi.encode(data))
            );

        // Find the output amount
        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }

    /**
     * @notice Single pool swap, calculate the as much as possible output amount for given input amount
     */
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut) {
        amountOut = exactInputInternal(
            params.amountIn,
            msg.sender,
            params.sqrtPriceLimitX96,
            SwapCallbackData({
                path: abi.encodePacked(params.tokenIn, params.tickSpacing, params.tokenOut), payer: msg.sender
            })
        );
    }

    /**
     * @notice Multiple pools swap, calculate the as much as possible output amount for given input amount
     */
    function exactInput(ExactInputParams memory params) external returns (uint256 amountOut) {
        // Determine the payer who will pay for the input amount to the pool
        // First, It's the someone who call this function. (msg.sender)
        address payer = msg.sender;
        bool hasMultiplePools;

        // Loop until all pools are processed
        while (true) {
            // Determine if has multiple pools
            hasMultiplePools = params.path.hasMultiplePools();

            // Update `params.amountIn` to the output amount
            // For pass to the next pool amountIn
            params.amountIn = exactInputInternal(
                params.amountIn,
                // Some one who will receive the output amount of the current pool being swapped
                // If has multiple pools, the SwapRouter contract will take `params.recipient`'s place to receive the output amount
                // And then as input amount to send to the next pool
                // If no more pools, then send the finial output amount to `params.recipient`
                hasMultiplePools ? address(this) : params.recipient,
                0,
                SwapCallbackData({path: params.path.getFirstPool(), payer: payer})
            );

            if (hasMultiplePools) {
                // Update the payer to the current contract (SwapRouter)
                payer = address(this);
                // Update the swap path
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }

            // Slippage check
            if (amountOut < params.amountOutMinimum) {
                revert TooLittleReceived(amountOut);
            }
        }
    }

    /**
     * @notice Single pool swap, calculate the as little as possible input amount for given output amount
     */
    function exactOutputSingle(ExactOutputSingleParams memory params) external returns (uint256 amountIn) {
        //
    }

    /**
     * @notice Multiple pools swap, calculate the as little as possible input amount for given output amount
     */
    function exactOutput(ExactOutputParams memory params) external returns (uint256 amountIn) {
        //
    }

    // External view  //////////////////

    // External pure  //////////////////

    ////////////////////////////////////
    // Public functions               //
    ////////////////////////////////////

    // Public view  ////////////////////

    // Public pure  ////////////////////

    ////////////////////////////////////
    // Internal functions             //
    ////////////////////////////////////

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
