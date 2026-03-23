// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "../core/Pool.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {IMintCallback} from "../interfaces/callback/IMintCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IFactory} from "../interfaces/IFactory.sol";

/* Libraries *****/
import {TickMath} from "../libraries/TickMath.sol";
import {LiquidityMath} from "../libraries/LiquidityMath.sol";

/**
 * @title  NonfungiblePositionManager
 * @author BTBMan
 * @notice This is a NonfungiblePositionManager Contract
 */
contract NonfungiblePositionManager is INonfungiblePositionManager, IMintCallback {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    // The address of the factory contract
    address public immutable factory;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor(address _factory) {
        factory = _factory;
    }

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    /**
     * @notice Create and initialize the pool if it does not exist
     */

    function mint(MintParams calldata params) public returns (uint256 amount0, uint256 amount1) {
        // Get pool contract
        IPool pool = IPool(IFactory(factory).getPool(params.token0, params.token1, 1));

        // Get current sqrt price of the current pool
        (uint160 sqrtPriceX96,) = pool.slot0();
        // Calculate tickLower/tickUpper sqrt price
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        // Calculate liquidity
        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96, sqrtPriceLowerX96, sqrtPriceUpperX96, params.amount0Desired, params.amount1Desired
        );

        // Mint(create position)
        (amount0, amount1) = pool.mint(
            address(this),
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(IPool.CallbackData({token0: pool.token0(), token1: pool.token1(), payer: msg.sender}))
        );

        // Check the slippage
        if (amount0 < params.amount0Min || amount1 < params.amount1Min) {
            revert SlippageCheckFailed(amount0, amount1);
        }
    }

    function createAndInitializePoolIfNecessary(address tokenA, address tokenB, uint24 fee, uint160 sqrtPriceX96)
        public
        returns (address pool)
    {
        pool = IFactory(factory).getPool(tokenA, tokenB, fee);

        if (pool == address(0)) {
            pool = IFactory(factory).createPool(tokenA, tokenB, fee);
            IPool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing,) = IPool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IPool(pool).initialize(sqrtPriceX96);
            }
        }
    }

    function mintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external {
        IPool.CallbackData memory extra = abi.decode(data, (IPool.CallbackData));

        // The msg.sender is the pool contract
        // Transfer the tokens from the payer to the pool
        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0Owed);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1Owed);
    }

    // External view  //////////////////

    // External pure  //////////////////

    ////////////////////////////////////
    // Public functions               //
    ////////////////////////////////////

    // Public view  ////////////////////

    // Public pure  ////////////////////

    ////////////////////////////////////
    // Internal functions             //
    ////////////////////////////////////

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
