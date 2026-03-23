// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IPool} from "./../interfaces/IPool.sol";
import {PoolAddress} from "./PoolAddress.sol";

library CallbackValidation {
    error InvalidPool(address pool, address sender);

    function verifyCallback(address factory, address tokenIn, address tokenOut, uint24 fee)
        internal
        view
        returns (IPool pool)
    {
        pool = IPool(PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenIn, tokenOut, fee)));

        if (address(pool) != msg.sender) {
            revert InvalidPool(address(pool), msg.sender);
        }
    }
}
