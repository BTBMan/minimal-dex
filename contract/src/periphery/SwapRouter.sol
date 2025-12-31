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
    function swap(address poolAddress, bytes calldata data) external override {
        Pool(poolAddress).swap(msg.sender, data);
    }

    function swapCallback(int256 amount0, int256 amount1, bytes calldata data) external override {
        SwapCallbackData memory extra = abi.decode(data, (SwapCallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0));
        }
        if (amount1 > 0) {
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1));
        }
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
