// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/
import "@prb/math/Common.sol";
import {FixedPoint96} from "./FixedPoint96.sol";
import {UnsafeMath} from "./UnsafeMath.sol";
import {FullMath} from "./FullMath.sol";

library SqrtPriceMath {
    error SqrtPriceMath__InvalidSqrtRatio();
    error SqrtPriceMath__InvalidLiquidity();

    /**
     * @notice Calculate the next sqrt price from input
     * @param sqrtPX96 The current sqrt price, before accounting for the input amount
     * @param liquidity The amount of liquidity
     * @param amountIn The amount of tokens remaining to be swapped
     * @param zeroForOne Whether the swap is zero for one
     * @return sqrtQX96 The next sqrt price after adding the input amount to token0 or token1
     */
    function getNextSqrtPriceFromInput(uint160 sqrtPX96, uint128 liquidity, uint256 amountIn, bool zeroForOne)
        internal
        pure
        returns (uint160 sqrtQX96)
    {
        if (sqrtPX96 <= 0) {
            revert SqrtPriceMath__InvalidSqrtRatio();
        }
        if (liquidity <= 0) {
            revert SqrtPriceMath__InvalidLiquidity();
        }

        return zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn)
            : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn);
    }

    /**
     * @notice Calculate the next sqrt price from the delta of token0
     */
    function getNextSqrtPriceFromAmount0RoundingUp(uint160 sqrtPX96, uint128 liquidity, uint256 amount)
        internal
        pure
        returns (uint160)
    {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;

        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 denominator;
        bool overflow;

        unchecked {
            uint256 product = amount * sqrtPX96;
            if ((product / amount != sqrtPX96) || ((denominator = numerator + product) < numerator)) overflow = true;
        }

        if (!overflow) {
            return uint160(FullMath.mulDivRoundingUp(numerator, sqrtPX96, denominator));
        }

        return uint160(UnsafeMath.divRoundingUp(numerator, (numerator / sqrtPX96) + amount));
    }

    /**
     * @notice Calculate the next sqrt price from the delta of token1
     */
    function getNextSqrtPriceFromAmount1RoundingDown(uint160 sqrtPX96, uint128 liquidity, uint256 amount)
        internal
        pure
        returns (uint160)
    {
        return sqrtPX96 + uint160((amount << FixedPoint96.RESOLUTION) / liquidity);
    }

    /**
     * @notice Calculate the amount0 delta between two prices
     * @param sqrtRatioAX96 The square root of the price A
     * @param sqrtRatioBX96 The square root of the price B
     * @param liquidity The amount of liquidity
     * @param roundUp Whether to round up or down
     * @return amount0 The amount of token0
     */
    function getAmount0Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
        // B must greater that A
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION; // EQ: L * 2^96
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        // Denominator must be greater than 0
        if (sqrtRatioAX96 <= 0) {
            revert SqrtPriceMath__InvalidSqrtRatio();
        }

        // Formula: x = L * ((sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower)))
        amount0 = roundUp
            ? UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96), sqrtRatioAX96)
            : mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /**
     * @notice Calculate the amount1 delta between two prices
     * @param sqrtRatioAX96 The square root of the price A
     * @param sqrtRatioBX96 The square root of the price B
     * @param liquidity The amount of liquidity
     * @param roundUp Whether to round up or down
     * @return amount1 The amount of token1
     */
    function getAmount1Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount1)
    {
        // B must greater that A
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        // Formula: y = L * (sqrt(upper) - sqrt(lower))
        amount1 = roundUp
            ? FullMath.mulDivRoundingUp(uint256(liquidity), sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
            : mulDiv(uint256(liquidity), sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }
}
