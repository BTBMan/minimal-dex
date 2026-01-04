// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/
import "@prb/math/Common.sol";
import {FixedPoint96} from "../libraries/FixedPoint96.sol";
import {UnsafeMath} from "../libraries/UnsafeMath.sol";
import {FullMath} from "../libraries/FullMath.sol";

library SqrtPriceMath {
    error SqrtPriceMath__InvalidSqrtRatio();

    /**
     * @notice Calculate the amount0 delta between two prices
     * @param sqrtRatioAX96 The square root of the price A
     * @param sqrtRatioBX96 The square root of the price B
     * @param liquidity The amount of liquidity
     * @param roundUp Whether to round up or down
     */
    function getAmount0Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity, bool roundUp)
        internal
        pure
        returns (uint256 amount0)
    {
        // B must greater that A
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        // Formula: x = L * ((sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower)))
        uint256 numerator1 = uint256(liquidity >> FixedPoint96.RESOLUTION);
        uint256 numerator2 = uint256(sqrtRatioBX96 - sqrtRatioAX96);

        if (sqrtRatioAX96 <= 0) {
            revert SqrtPriceMath__InvalidSqrtRatio();
        }

        amount0 = roundUp
            ? UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96), sqrtRatioAX96)
            : mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }
}
