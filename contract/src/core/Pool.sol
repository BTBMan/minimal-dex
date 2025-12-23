// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";

/* Events ********/

/* Errors ********/

/* Interfaces ****/
import {IPool} from "../interfaces/IPool.sol";

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
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }
    Slot0 public slot0;

    // Amount of liquidity, L.
    uint128 public liquidity;

    // Tick info
    mapping(int24 tick => Tick.Info) public ticks;
    // Positions info
    // Position key is the bytes32 keccak256(owner, tickLower, tickUpper)
    mapping(bytes32 => Position.Info) public positions;

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
     */
    function mint(address owner, int24 tickLower, int24 tickUpper, uint128 amount)
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

        // Transferring ...

        // Validate balance after transfer
        if (amount > 0 && balance0Before + amount > balance0()) {
            revert InsufficientInputAmount();
        }
        if (amount > 0 && balance1Before + amount > balance1()) {
            revert InsufficientInputAmount();
        }

        emit Mint(msg.sender, owner, tickLower, tickUpper, amount, amount0, amount1);
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
