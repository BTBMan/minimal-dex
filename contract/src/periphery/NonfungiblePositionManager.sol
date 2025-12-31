// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {IMintCallback} from "../interfaces/callback/IMintCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Libraries *****/

/**
 * @title  NonfungiblePositionManager
 * @author BTBMan
 * @notice This is a NonfungiblePositionManager Contract
 */
contract NonfungiblePositionManager is INonfungiblePositionManager, IMintCallback {
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
    /**
     * @notice Create and initialize the pool if it does not exist
     */
    // function createAndInitializePoolIfNecessary() external {
    //     //
    // }

    function mint(address poolAddress, int24 tickLower, int24 tickUpper, uint128 liquidity, bytes calldata data)
        external
    {
        Pool(poolAddress).mint(msg.sender, tickLower, tickUpper, liquidity, data);
    }

    function mintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        MintCallbackData memory extra = abi.decode(data, (MintCallbackData));

        // The msg.sender is the pool contract
        // Transfer the tokens from the payer to the pool
        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
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
