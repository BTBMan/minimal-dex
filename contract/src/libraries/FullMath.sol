// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@prb/math/Common.sol";

library FullMath {
    error PRBMathMulDivOverflow();

    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) external pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                if (result >= type(uint256).max) {
                    revert PRBMathMulDivOverflow();
                }

                result++;
            }
        }
    }
}
