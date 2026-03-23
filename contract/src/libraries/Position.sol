// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/

/* Libraries *****/
import "@prb/math/common.sol";
import {LiquidityMath} from "./LiquidityMath.sol";
import {FixedPoint128} from "./FixedPoint128.sol";

library Position {
    struct Info {
        uint128 liquidity;
        // The fee growth as of the last update to liquidity or fees owed
        // If add liquidity in the same tick lower and tick upper multiple times, It's useful
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // The fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function update(
        Info storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        uint128 tokensOwed0 = uint128(
            mulDiv(feeGrowthInside0X128 - self.feeGrowthInside0LastX128, self.liquidity, FixedPoint128.Q128)
        );

        uint128 tokensOwed1 =
            uint128(mulDiv(feeGrowthInside1X128 - self.feeGrowthInside1LastX128, self.liquidity, FixedPoint128.Q128));

        self.liquidity = LiquidityMath.addDelta(self.liquidity, liquidityDelta);

        // Update last fee growth
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;

        // Updata tokens owed
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }

    /**
     * Get position info
     */
    function get(mapping(bytes32 => Info) storage self, address owner, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (Info storage info)
    {
        info = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
    }
}
