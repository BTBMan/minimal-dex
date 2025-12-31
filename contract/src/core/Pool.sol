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

/* Libraries *****/
import {Tick} from "../libraries/Tick.sol";
import {Position} from "../libraries/Position.sol";

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

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    // Min/Max tick
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Pool tokens
    address public immutable token0;
    address public immutable token1;

    // Current price and its corresponding tick
    Slot0 public slot0;

    // Amount of liquidity, L.
    uint128 public liquidity;

    // Tick info
    mapping(int24 tick => Tick.Info) public ticks;
    // Positions info
    // Position key is the bytes32 keccak256(owner, tickLower, tickUpper)
    mapping(bytes32 => Position.Info) public positions;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    /**
     * @notice Parameters to be passed when creating a pool in the factory
     * @param _token0 The address of the first token
     * @param _token1 The address of the second token
     * @param sqrtPriceX96 The current sqrt price Q96
     * @param tick The current price tick
     */
    constructor(address _token0, address _token1, uint160 sqrtPriceX96, int24 tick) {
        token0 = _token0;
        token1 = _token1;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }

    ////////////////////////////////////
    // Receive & Fallback             //
    ////////////////////////////////////

    ////////////////////////////////////
    // External functions             //
    ////////////////////////////////////
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

        // Update liquidity
        liquidity += amount;

        // Update tick info
        ticks.update(tickLower, amount);
        ticks.update(tickUpper, amount);

        // Update position info
        Position.Info storage position = positions.get(owner, tickLower, tickUpper);
        position.update(amount);

        // Hardcode amount0 and amount1 for now
        amount0 = 0.99897661834742528 ether;
        amount1 = 5000 ether;

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
        // Can not let user transfer directly cuz we don't trust user
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

    /**
     * @notice Swap tokens
     * @param recipient The recipient of the tokens
     * @param data Data to be passed to the callback function
     */
    function swap(address recipient, bytes calldata data) external returns (int256 amount0, int256 amount1) {
        // Hardcode variables
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;

        // Update slot0
        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);

        // Send token to recipient
        // forge-lint: disable-next-line(unsafe-typecast)
        bool success = IERC20(token0).transfer(recipient, uint256(-amount0)); // ETH
        if (!success) {
            revert SwapFailed();
        }

        uint256 balance1Before = balance1();

        // Transfer the token provided by the user to the contract
        ISwapCallback(msg.sender).swapCallback(amount0, amount1, data);

        // Validate
        if (balance1Before + uint256(amount1) < balance1()) {
            revert InsufficientInputAmount();
        }

        emit Swap(msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);
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
