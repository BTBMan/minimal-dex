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

/* Libraries *****/

/**
 * @title SwapRouter
 * @author BTBMan
 * @notice This is a contract
 */
contract SwapRouter is ISwapRouter, ISwapCallback {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor() {}

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        SwapCallbackData memory extra = abi.decode(data, (SwapCallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0Delta > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1Delta));
        }
    }

    /**
     * @notice Multiple pools swap, calculate the as much as possible output amount for given input amount
     */
    function exactInput(address poolAddress, bytes calldata data) external {
        //
    }

    /**
     * @notice Single pool swap, calculate the as much as possible output amount for given input amount
     */
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut) {
        // Pool(params.pool).swap(msg.sender, params.zeroForOne, params.amountIn, abi.encode(params.pool));
    }

    /**
     * @notice Multiple pools swap, calculate the as little as possible input amount for given output amount
     */
    function exactOutput(address poolAddress, bytes calldata data) external {
        //
    }

    /**
     * @notice Single pool swap, calculate the as little as possible input amount for given output amount
     */
    function exactOutputSingle(address poolAddress, bytes calldata data) external {
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
