// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IMintCallback} from "../interfaces/callback/IMintCallback.sol";
import {ISwapCallback} from "../interfaces/callback/ISwapCallback.sol";
import {IFlashCallback} from "../interfaces/callback/IFlashCallback.sol";
import {IPoolDeployer} from "../interfaces/IPoolDeployer.sol";

/* Libraries *****/
import {Tick} from "../libraries/Tick.sol";
import {Position} from "../libraries/Position.sol";
import {TickBitmap} from "../libraries/TickBitmap.sol";
import {SqrtPriceMath} from "./../libraries/SqrtPriceMath.sol";
import {TickMath} from "./../libraries/TickMath.sol";
import {SwapMath} from "./../libraries/SwapMath.sol";
import {LiquidityMath} from "./../libraries/LiquidityMath.sol";

/**
 * @title Pool
 * @author BTBMan
 * @notice This is a Uniswap Pool Contract
 */
contract Pool is IPool {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////
    using Tick for mapping(int24 tick => Tick.Info);
    using Position for mapping(bytes32 tick => Position.Info);
    using Position for Position.Info;
    using TickBitmap for mapping(int16 word => uint256 tick);

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    // Min/Max tick
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Pool tokens
    address public immutable token0;
    address public immutable token1;

    // Factory contract
    address public immutable factory;

    // Tick spacing
    int24 internal immutable tickSpacing;

    // Fee
    uint24 internal immutable fee;

    // Current price and its corresponding tick
    Slot0 public slot0;

    // Amount of liquidity, L.
    uint128 public liquidity;

    // Tick info
    mapping(int24 tick => Tick.Info) public ticks;
    // Positions info
    // Position key is the bytes32 keccak256(owner, tickLower, tickUpper)
    mapping(bytes32 => Position.Info) public positions;
    // Tick bitmap
    mapping(int16 word => uint256 tick) public tickBitmap;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor() {
        // Get parameters from deployer
        (factory, token0, token1, fee, tickSpacing) = IPoolDeployer(msg.sender).parameters();
    }

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
    /**
     * @notice Initialize the pool
     * @param sqrtPriceX96 The initial sqrt price Q96
     */
    function initialize(uint160 sqrtPriceX96) external {
        if (slot0.sqrtPriceX96 != 0) {
            revert AlreadyInitialized();
        }

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});

        emit Initialize(sqrtPriceX96, tick);
    }

    /**
     * @notice Provide liquidity
     * @param owner The owner of the position
     * @param tickLower The lower tick of the position
     * @param tickUpper The upper tick of the position
     * @param amount The amount of liquidity to provide
     * @param data Data to be passed to the callback function
     */
    function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        // Invalid tick range
        if (tickLower >= tickUpper || tickLower < MIN_TICK || tickUpper > MAX_TICK) {
            revert InvalidTickRange();
        }

        // Invalid amount
        if (amount == 0) {
            revert ZeroLiquidity();
        }

        Slot0 memory _slot0 = slot0;

        // Update tick info
        bool flippedLower = ticks.update(tickLower, int128(amount), false);
        bool flippedUpper = ticks.update(tickUpper, int128(amount), true);

        // Update tick bitmap liquidity
        if (flippedLower) {
            tickBitmap.flipTick(tickLower, tickSpacing);
        }
        if (flippedUpper) {
            tickBitmap.flipTick(tickUpper, tickSpacing);
        }

        // Update position info
        Position.Info storage position = positions.get(owner, tickLower, tickUpper);
        position.update(amount);

        // Determine if the current price is within the tick range to calculate amount0 and amount1
        if (_slot0.tick < tickLower) {
            // Out of range, amount1(token y) is 0, need to calculate amount0(token x)
            amount0 = SqrtPriceMath.getAmount0Delta(
                TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), amount, true
            );
        } else if (_slot0.tick < tickUpper) {
            // In range, need to calculate both amount0(token x) and amount1(token y)
            amount0 = SqrtPriceMath.getAmount0Delta(
                _slot0.sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickUpper), amount, true
            );

            amount1 = SqrtPriceMath.getAmount1Delta(
                _slot0.sqrtPriceX96, TickMath.getSqrtRatioAtTick(tickLower), amount, true
            );

            // Update liquidity
            liquidity += amount;
        } else {
            // Out of range, amount0(token x) is 0, need to calculate amount1(token y)
            amount1 = SqrtPriceMath.getAmount1Delta(
                TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), amount, true
            );
        }

        // Get token from user
        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) {
            balance0Before = balance0();
        }
        if (amount1 > 0) {
            balance1Before = balance1();
        }

        // Transferring, use contract callback function to execute
        // Can not let users transfer directly cuz we don't trust users
        // We should deployed a contract that implements callback function we defined
        IMintCallback(msg.sender).mintCallback(amount0, amount1, data);

        // Validate balance after transfer
        if (amount0 > 0 && balance0Before + amount0 > balance0()) {
            revert InsufficientInputAmount();
        }
        if (amount1 > 0 && balance1Before + amount1 > balance1()) {
            revert InsufficientInputAmount();
        }

        emit Mint(msg.sender, owner, tickLower, tickUpper, amount, amount0, amount1);
    }

    struct SwapState {
        // The amount of tokens remaining to be swapped
        uint256 amountSpecifiedRemaining;
        // The amount already swapped
        uint256 amountCalculated;
        // Current sqrt(price)
        uint160 sqrtPriceX96;
        // The tick associated with the current price
        int24 tick;
        // Current liquidity of the tick range
        uint128 liquidity;
    }

    struct StepComputations {
        // The price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // The next tick to swap to
        int24 nextTick;
        // The price for the next tick
        uint160 sqrtPriceNextX96;
        // Swap in amount
        uint256 amountIn;
        // Swap out amount
        uint256 amountOut;
    }

    /**
     * @notice Swap tokens
     * @param recipient The recipient of the tokens
     * @param zeroForOne Whether the swap is token0 for token1
     * @param amountSpecified Expected amount of the tokens to be sold
     * @param sqrtPriceLimitX96 The price limit for the swap
     * @param data Data to be passed to the callback function
     */
    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        Slot0 memory slot0Start = slot0;
        uint128 liquidity_ = liquidity;

        // Slippage protection step 1: Ensure the sqrtPriceLimitX96 must be set correctly
        // zeroForOne: ⤵️ TickMath.MIN_SQRT_RATIO < sqrtPriceLimitX96 < sqrtPrice ✅
        // oneForZero: ⤴️ TickMath.MAX_SQRT_RATIO > sqrtPriceLimitX96 > sqrtPrice ✅
        // Otherwise revert
        if (zeroForOne
                ? sqrtPriceLimitX96 >= slot0Start.sqrtPriceX96 || sqrtPriceLimitX96 <= TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 <= slot0Start.sqrtPriceX96 || sqrtPriceLimitX96 >= TickMath.MAX_SQRT_RATIO) {
            revert InvalidSqrtPriceLimitX96();
        }

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            liquidity: liquidity_
        });

        // The order is filled when amountSpecifiedRemaining is 0
        // Make sure the state sqrt price not equal to the sqrt price limit
        while (state.amountSpecifiedRemaining > 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            // Get the price boundary tick(tickLower or tickUpper, or overlapping part)
            (step.nextTick,) = tickBitmap.nextInitializedTickWithinOneWord(state.tick, tickSpacing, zeroForOne);

            // Get the sqrt price of the boundary tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            // Compute the swap step
            // Get the target sqrt price for the specified token trade amount(and re-assigned to state.sqrtPriceX96)
            // Get the actual token trade amount(and assigned to step.amountIn)
            // Get the actual token received amount(and assigned to step.amountOut)
            //
            // Slippage protection step 2: Ensure the next sqrt price within the sqrt price limit
            (state.sqrtPriceX96, step.amountIn, step.amountOut) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining
            );

            // Reach the tick boundary
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                int128 liquidityDelta = ticks.cross(step.nextTick);

                // Determine if token 0 for token 1
                if (zeroForOne) liquidityDelta = -liquidityDelta;

                // Update state liquidity
                state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityDelta);

                // Actually, not doing this in Uniswap
                if (state.liquidity == 0) revert NotEnoughLiquidity();

                // Update tick
                // If price decreasing, tick should be the tickLower decreased by 1
                //
                // If price increasing, tick should be the tickUpper, don't need to increase by 1
                // because in `nextInitializedTickWithinOneWord`, It's finding the next initialized tick from the given tick increasing by 1
                state.tick = zeroForOne ? step.nextTick - 1 : step.nextTick;
            } else {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }

            // Update state
            state.amountSpecifiedRemaining -= step.amountIn;
            state.amountCalculated += step.amountOut;
        }

        // Update liquidity
        // Means it moved to the next tick range
        if (liquidity_ != state.liquidity) {
            liquidity = state.liquidity;
        }

        // Update token amounts
        (amount0, amount1) = zeroForOne
            ? (int256(amountSpecified - state.amountSpecifiedRemaining), -int256(state.amountCalculated))
            : (-int256(state.amountCalculated), int256(amountSpecified - state.amountSpecifiedRemaining));

        // Update slot0
        if (state.tick != slot0Start.tick) {
            (slot0.tick, slot0.sqrtPriceX96) = (state.tick, state.sqrtPriceX96);
        }

        // Send token to recipient
        if (zeroForOne) {
            // forge-lint: disable-next-line(unsafe-typecast)
            bool success = IERC20(token1).transfer(recipient, uint256(-amount1));
            if (!success) {
                revert SwapFailed();
            }

            uint256 balance0Before = balance0();

            // Transfer the token provided by the user(token0) to the contract
            ISwapCallback(msg.sender).swapCallback(amount0, amount1, data);

            // Validate
            if (balance0Before + uint256(amount0) < balance0()) {
                revert InsufficientInputAmount();
            }
        } else {
            // forge-lint: disable-next-line(unsafe-typecast)
            bool success = IERC20(token0).transfer(recipient, uint256(-amount0));
            if (!success) {
                revert SwapFailed();
            }

            uint256 balance1Before = balance1();

            // Transfer the token provided by the user(token1) to the contract
            ISwapCallback(msg.sender).swapCallback(amount0, amount1, data);

            // Validate
            if (balance1Before + uint256(amount1) < balance1()) {
                revert InsufficientInputAmount();
            }
        }

        emit Swap(msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);
    }

    function flash(uint256 amount0, uint256 amount1, bytes calldata data) external {
        // Balance of the pool before lend tokens
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        // Transfer to msg.sender
        if (amount0 > 0) {
            IERC20(token0).transfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).transfer(msg.sender, amount1);
        }

        // Call the callback function
        IFlashCallback(msg.sender).flashCallback(data);

        if (balance0Before < balance0() || balance1Before < balance1()) {
            revert FlashLoanNotPaid();
        }

        emit Flash(msg.sender, amount0, amount1);
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
    function balance0() private view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balance1() private view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

    // Private view ////////////////////

    // Private pure ////////////////////
}
