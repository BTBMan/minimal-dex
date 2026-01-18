// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library UnsafeMath {
    function divRoundingUp(uint256 numerator, uint256 denominator) external pure returns (uint256 result) {
        assembly {
            result := add(div(numerator, denominator), gt(mod(numerator, denominator), 0))
        }
    }
}
