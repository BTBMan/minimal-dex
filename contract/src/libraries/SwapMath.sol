// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {SqrtPriceMath} from "./SqrtPriceMath.sol";

library SwapMath {
    /**
     * @notice Compute the next sqrt price and token amountIn/amountOut in swap
     * @param sqrtPriceCurrentX96 The current sqrt price
     * @param sqrtPriceTargetX96 The target sqrt price
     * @param liquidity The usable liquidity
     * @param amountRemaining The amount of tokens remaining to be swapped
     * @return sqrtPriceNextX96 The next sqrt price
     * @return amountIn The amount to be swapped in by user
     * @return amountOut The amount to be received by user
     */
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining
    ) internal pure returns (uint160 sqrtPriceNextX96, uint256 amountIn, uint256 amountOut) {
        // Determine the direction of the swap
        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;

        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, true)
            : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, true);

        // determine if amountIn > amountRemaining
        // If not satisfied, jump to the next tick range if it exists (doing this in the swap function)
        // That means reached the tick range boundary, we should set sqrtPriceNextX96 to sqrtPriceTargetX96(the price at the boundary)
        if (amountRemaining >= amountIn) {
            sqrtPriceNextX96 = sqrtPriceTargetX96;
        } else {
            sqrtPriceNextX96 =
                SqrtPriceMath.getNextSqrtPriceFromInput(sqrtPriceCurrentX96, liquidity, amountRemaining, zeroForOne);
        }

        amountIn = SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, true);
        amountOut = SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, true);

        if (!zeroForOne) (amountIn, amountOut) = (amountOut, amountIn);
    }
}
