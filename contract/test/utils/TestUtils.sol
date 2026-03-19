// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {Pool} from "../../src/core/Pool.sol";
import {Factory} from "../../src/core/Factory.sol";

/* Interfaces ****/
import {INonfungiblePositionManager} from "../../src/interfaces/INonfungiblePositionManager.sol";
import {IMintCallback} from "../../src/interfaces/callback/IMintCallback.sol";
import {ISwapCallback} from "../../src/interfaces/callback/ISwapCallback.sol";
import {IFlashCallback} from "../../src/interfaces/callback/IFlashCallback.sol";
import {IPool} from "../../src/interfaces/IPool.sol";

/* Libraries *****/
import {sd, sqrt} from "@prb/math/SD59x18.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ABDKMath64x64} from "@abdk/math/ABDKMath64x64.sol";
import {TickMath} from "./../../src/libraries/TickMath.sol";
import {FixedPoint96} from "./../../src/libraries/FixedPoint96.sol";
import {LiquidityMath} from "./../../src/libraries/LiquidityMath.sol";
import {Assertions} from "./Assertions.sol";

abstract contract TestUtils is Test, Assertions, IMintCallback, ISwapCallback, IFlashCallback {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////
    struct LiquidityRange {
        int24 tickLower;
        int24 tickUpper;
        uint128 amount;
    }

    struct PoolParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint160 currentPrice;
        LiquidityRange[] liquidity;
        bool shouldTransferInCallback;
        bool mintLiquidity;
    }

    Factory public factory;
    Pool public pool;
    ERC20Mock public token0; // ETH
    ERC20Mock public token1; // USDC

    bool public shouldTransferInCallback;
    bool public flashCallbackCalled;

    address public user = makeAddr("user");

    uint256 public constant STARTING_BALANCE = 1 ether;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // functions             //
    ////////////////////////////////////
    function setUp() public virtual {
        ERC20Mock _tokenA = new ERC20Mock();
        ERC20Mock _tokenB = new ERC20Mock();

        // Ensure token0 address < token1 address (same rule as Factory)
        if (address(_tokenA) < address(_tokenB)) {
            token0 = _tokenA;
            token1 = _tokenB;
        } else {
            token0 = _tokenB;
            token1 = _tokenA;
        }

        factory = new Factory();
        vm.deal(user, STARTING_BALANCE);
    }

    function tick(uint256 price) public pure returns (int24 tick_) {
        tick_ = TickMath.getTickAtSqrtRatio(
            uint160(int160(ABDKMath64x64.sqrt(int128(int256(price << 64))) << (FixedPoint96.RESOLUTION - 64)))
        );
    }

    function sqrtP(uint256 price) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick(price));
    }

    function encodeError(string memory error) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function liquidityRange(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1,
        uint256 currentPrice
    ) internal pure returns (LiquidityRange memory range) {
        range = LiquidityRange({
            tickLower: tick(lowerPrice),
            tickUpper: tick(upperPrice),
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP(currentPrice), sqrtP(lowerPrice), sqrtP(upperPrice), amount0, amount1
            )
        });
    }

    function liquidityRange(uint256 lowerPrice, uint256 upperPrice, uint128 amount)
        internal
        pure
        returns (LiquidityRange memory range)
    {
        range = LiquidityRange({tickLower: tick(lowerPrice), tickUpper: tick(upperPrice), amount: amount});
    }

    function rangeToTicks(LiquidityRange memory range) internal pure returns (ExpectedTickShort[2] memory ticks) {
        ticks[0] = ExpectedTickShort({
            tick: range.tickLower, initialized: true, liquidityGross: range.amount, liquidityNet: int128(range.amount)
        });
        ticks[1] = ExpectedTickShort({
            tick: range.tickUpper, initialized: true, liquidityGross: range.amount, liquidityNet: -int128(range.amount)
        });
    }

    function mintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external virtual override {
        if (shouldTransferInCallback) {
            INonfungiblePositionManager.MintCallbackData memory extra =
                abi.decode(data, (INonfungiblePositionManager.MintCallbackData));

            // The msg.sender is the pool contract
            // Transfer the tokens from the payer to the pool
            token0.transferFrom(extra.payer, msg.sender, amount0Owed);
            token1.transferFrom(extra.payer, msg.sender, amount1Owed);
        }
    }

    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external virtual override {
        IPool.CallbackData memory extra = abi.decode(data, (IPool.CallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0Delta > 0) {
            token0.transferFrom(extra.payer, msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            token1.transferFrom(extra.payer, msg.sender, uint256(amount1Delta));
        }
    }

    function flashCallback(bytes calldata data) external virtual override {
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));

        if (amount0 > 0) {
            token0.transfer(msg.sender, amount0);
        }
        if (amount1 > 0) {
            token1.transfer(msg.sender, amount1);
        }

        flashCallbackCalled = true;
    }

    function setupTestCase(PoolParams memory poolParams)
        public
        virtual
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        // Create pool
        pool = Pool(factory.createPool(address(token0), address(token1), 1));
        pool.initialize(sqrtP(poolParams.currentPrice));

        shouldTransferInCallback = poolParams.shouldTransferInCallback;

        // Mint tokens to this test contract
        token0.mint(address(this), poolParams.wethBalance);
        token1.mint(address(this), poolParams.usdcBalance);

        // Add liquidity from liquidity array
        if (poolParams.mintLiquidity) {
            // Approve tokens to the current test contract first
            token0.approve(address(this), poolParams.wethBalance);
            token1.approve(address(this), poolParams.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < poolParams.liquidity.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    poolParams.liquidity[i].tickLower,
                    poolParams.liquidity[i].tickUpper,
                    poolParams.liquidity[i].amount,
                    abi.encode(token0, token1, address(this))
                );

                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }
    }
}
