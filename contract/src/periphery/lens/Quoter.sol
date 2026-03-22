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
import {IPool} from "../../interfaces/IPool.sol";

/* Libraries *****/
import {TickMath} from "../../libraries/TickMath.sol";
import {Path} from "../../libraries/Path.sol";
import {PoolAddress} from "../../libraries/PoolAddress.sol";
import {CallbackValidation} from "../../libraries/CallbackValidation.sol";

/**
 * @title Quoter
 * @author BTBMan
 * @notice This is a contract
 */
contract Quoter is IQuoter, ISwapCallback {
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
    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory path) external view {
        (address tokenIn, address tokenOut, int24 tickSpacing) = path.decodeFirstPool();

        // Verify the pool which is calling this function is the same as the one in the data
        CallbackValidation.verifyCallback(factory, tokenIn, tokenOut, tickSpacing);

        bool zeroForOne = tokenIn < tokenOut;

        uint256 amountToPay = zeroForOne ? uint256(-amount1Delta) : uint256(-amount0Delta);

        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amountToPay)
            revert(ptr, 32)
        }
    }

    /**
     * @notice Get pool address by given tokenA, tokenB and tickSpacing
     */
    function getPool(address tokenA, address tokenB, int24 tickSpacing) private view returns (IPool pool) {
        pool = IPool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, tickSpacing)));
    }

    function parseReason(bytes memory reason) private pure returns (uint256 amountDelta) {
        amountDelta = abi.decode(reason, (uint256));
    }

    /**
     * @notice Single pool swap, calculate the as much as possible output amount for given input amount
     */
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) public returns (uint256 amountOut) {
        bool zeroForOne = tokenIn < tokenOut;

        try getPool(tokenIn, tokenOut, tickSpacing)
            .swap(
                // address(this) just for calculation
                // address(0) has some problem
                address(this),
                zeroForOne,
                amountIn,
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                (abi.encodePacked(tokenIn, tickSpacing, tokenOut))
            ) {}
        catch (bytes memory reason) {
            return parseReason(reason);
        }
    }

    /**
     * @notice Multiple pools swap, calculate the as much as possible output amount for given input amount
     */
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut) {
        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();

            (address tokenIn, address tokenOut, int24 tickSpacing) = path.decodeFirstPool();

            amountIn = quoteExactInputSingle(tokenIn, tokenOut, tickSpacing, amountIn, 0);

            if (hasMultiplePools) {
                path = path.skipToken();
            } else {
                amountOut = amountIn;
                break;
            }
        }
    }

    /**
     * @notice Single pool swap, calculate the as little as possible input amount for given output amount
     */
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        int24 tickSpacing,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn) {
        //
    }

    /**
     * @notice Multiple pools swap, calculate the as little as possible input amount for given output amount
     */
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn) {
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
