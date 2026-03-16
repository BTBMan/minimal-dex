// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "../../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {IQuoter} from "../../interfaces/IQuoter.sol";
import {ISwapCallback} from "../../interfaces/callback/ISwapCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* Libraries *****/
import {TickMath} from "../../libraries/TickMath.sol";

/**
 * @title Quoter
 * @author BTBMan
 * @notice This is a contract
 */
contract Quoter is IQuoter, ISwapCallback {
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
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external pure {
        abi.decode(data, (address));
        // (address pool) = abi.decode(data, (address));
        // SwapCallbackData memory data = abi.decode(data, (SwapCallbackData));

        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amountToPay)
            revert(ptr, 32)
        }
    }

    /**
     * @notice Calculate the as much as possible output amount for given input amount
     * @dev Just a test function
     */
    function quote(address pool, uint256 amountIn, uint160 sqrtPriceLimitX96, bool zeroForOne)
        external
        returns (uint256 amountOut)
    {
        // address(this) just for calculation
        try Pool(pool)
            .swap(
                address(this),
                zeroForOne,
                amountIn,
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                (abi.encode(pool))
            ) {}
        catch (bytes memory reason) {
            return abi.decode(reason, (uint256));
        }
    }

    // /**
    //  * @notice Multiple pools swap, calculate the as much as possible output amount for given input amount
    //  */
    // function quoteExactInput(address poolAddress, bytes calldata data) external {
    //     //
    // }

    // /**
    //  * @notice Single pool swap, calculate the as much as possible output amount for given input amount
    //  */
    // function quoteExactInputSingle(address pool, uint256 amountIn, bool zeroForOne)
    //     external
    //     returns (uint256 amountOut)
    // {
    //     Pool(pool).swap(msg.sender, zeroForOne, amountIn, abi.encode(pool));
    // }

    // /**
    //  * @notice Multiple pools swap, calculate the as little as possible input amount for given output amount
    //  */
    // function exactOutput(address poolAddress, bytes calldata data) external {
    //     //
    // }

    // /**
    //  * @notice Single pool swap, calculate the as little as possible input amount for given output amount
    //  */
    // function exactOutputSingle(address poolAddress, bytes calldata data) external {
    //     //
    // }

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
