// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

import "@prb/math/Common.sol";

library UnsafeMath {
    function divRoundingUp(uint256 numerator, uint256 denominator) external pure returns (uint256 result) {
        assembly {
            result := add(div(numerator, denominator), gt(mod(numerator, denominator), 0))
        }
    }
}
