// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {INonfungibleTokenPositionDescriptor} from "../interfaces/INonfungibleTokenPositionDescriptor.sol";
import {IPool} from "../interfaces/IPool.sol";
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";

/* Libraries *****/
import {PoolAddress} from "./../libraries/PoolAddress.sol";
import {NFTDescriptor} from "./../libraries/NFTDescriptor.sol";

/**
 * @title  NonfungibleTokenPositionDescriptor
 * @author BTBMan
 * @notice This is a NonfungibleTokenPositionDescriptor Contract
 */
contract NonfungibleTokenPositionDescriptor is INonfungibleTokenPositionDescriptor {
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
     * @notice Return A JSON for given position manager contract and a tokenId
     * @return A metadata URI
     *
     * example:
     * {
     *   "name": "Minimal Dex Position",
     *   "description": "USDC/ETH 0.05%, Tick lower: -520, Tick upper: 490",
     *   "image": "base64 SVG"
     * }
     */
    function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        (address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper) =
            positionManager.positions(tokenId);

        IPool pool =
            IPool(PoolAddress.computeAddress(positionManager.factory(), PoolAddress.getPoolKey(token0, token1, fee)));

        return NFTDescriptor.constructTokenURI(
            NFTDescriptor.ConstructTokenURIParams({
                token0: token0,
                token1: token1,
                poolAddress: address(pool),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper
            })
        );
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
