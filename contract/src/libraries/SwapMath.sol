// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@prb/math/common.sol";
import {FullMath} from "./FullMath.sol";
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
        uint256 amountRemaining,
        uint24 feePips
    ) internal pure returns (uint160 sqrtPriceNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) {
        // Determine the direction of the swap
        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;
        // Calculate the amount remaining after deducting the fee
        // amountRemaining * (1e6 - feePips) / 1e6
        // 1e6 = 1000000 fee = 100%
        uint256 amountRemainingLessFee = mulDiv(amountRemaining, (1e6 - feePips), 1e6);

        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, true)
            : SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceTargetX96, liquidity, true);

        // Determine if amountIn > amountRemainingLessFee
        // If not satisfied, jump to the next tick range if it exists (doing this in the swap function)
        // That means reached the tick range boundary, we should set sqrtPriceNextX96 to sqrtPriceTargetX96(the price at the boundary)
        if (amountRemainingLessFee >= amountIn) {
            sqrtPriceNextX96 = sqrtPriceTargetX96;
        } else {
            sqrtPriceNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtPriceCurrentX96, liquidity, amountRemainingLessFee, zeroForOne
            );
        }

        amountIn = SqrtPriceMath.getAmount0Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, true);
        amountOut = SqrtPriceMath.getAmount1Delta(sqrtPriceCurrentX96, sqrtPriceNextX96, liquidity, true);

        if (!zeroForOne) (amountIn, amountOut) = (amountOut, amountIn);

        // Determine if price reached tick boundary
        // To calculate the feeAmount
        bool max = sqrtPriceNextX96 == sqrtPriceTargetX96;
        if (!max) {
            // If not reached the boundary, use amountRemaining minus actual amountIn
            // amountRemaining = net + fee
            // amountIn = net amount
            // fee = amountRemaining - amountIn
            feeAmount = amountRemaining - amountIn;
        } else {
            // If reached the boundary, reverse calculate the fee
            // fee_rate = (1e6 - feePips) / 1e6
            // net = total * fee_rate
            // total = net / fee_rate
            // total = amountIn / ((1e6 - feePips) / 1e6)
            // total = amountIn * 1e6 / (1e6 - feePips)
            // feeAmount = total - net
            // feeAmount = amountIn * 1e6 / (1e6 - feePips) - amountIn
            // feeAmount = amountIn * (1e6 / (1e6 - feePips) - 1)
            // feeAmount = amountIn * ((1e6 / (1e6 - feePips)) - ((1e6 - feePips) / (1e6 - feePips)))
            // feeAmount = amountIn * ((1e6 - (1e6 - feePips)) / (1e6 - feePips))
            // feeAmount = amountIn * ((1e6 - 1e6 + feePips) / (1e6 - feePips))
            // feeAmount = amountIn * (feePips / (1e6 - feePips))
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}
