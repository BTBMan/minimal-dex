// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library SwapMath {
    /**
     * @notice Compute the next sqrt price in the swap
     * @param sqrtPriceCurrentX96 The current sqrt price
     * @param sqrtPriceTargetX96 The target sqrt price
     * @param liquidity The usable liquidity
     * @param amountRemaining The amount of tokens remaining to be swapped
     * @return sqrtPriceNextX96 The next sqrt price
     * @return amountIn The amount to be swapped in by the user
     * @return amountOut The amount to be received by the user
     */
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining
    ) internal pure returns (uint160 sqrtPriceNextX96, uint256 amountIn, uint256 amountOut) {
        // Determine the direction of the swap
        bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;
    }
}
