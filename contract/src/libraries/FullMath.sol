// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

import "@prb/math/Common.sol";

library FullMath {
    error PRBMathMulDivOverflow();

    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) external pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            if (result >= type(uint256).max) {
                revert PRBMathMulDivOverflow();
            }

            result++;
        }
    }
}
