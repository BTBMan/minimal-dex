// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "./Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {IPoolDeployer} from "../interfaces/IPoolDeployer.sol";

/* Libraries *****/

/**
 * @title PoolDeployer
 * @author BTBMan
 * @notice This is a contract
 */
contract PoolDeployer is IPoolDeployer {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    Parameters public override parameters;

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
    function deploy(address factory, address token0, address token1, int24 tickSpacing)
        internal
        returns (address pool)
    {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, tickSpacing: tickSpacing});
        pool = address(new Pool{salt: keccak256(abi.encodePacked(token0, token1, tickSpacing))}());
        delete parameters;
    }

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
