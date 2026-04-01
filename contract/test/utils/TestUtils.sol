// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import {FactoryScript} from "../../script/Factory.s.sol";
import {NonfungibleTokenPositionDescriptorScript} from "../../script/NonfungibleTokenPositionDescriptor.s.sol";
import {Pool} from "../../src/core/Pool.sol";
import {Factory} from "../../src/core/Factory.sol";
import {NonfungibleTokenPositionDescriptor} from "../../src/periphery/NonfungibleTokenPositionDescriptor.sol";

/* Interfaces ****/
import {INonfungiblePositionManager} from "../../src/interfaces/INonfungiblePositionManager.sol";
import {IMintCallback} from "../../src/interfaces/callback/IMintCallback.sol";
import {ISwapCallback} from "../../src/interfaces/callback/ISwapCallback.sol";
import {IFlashCallback} from "../../src/interfaces/callback/IFlashCallback.sol";
import {IPool} from "../../src/interfaces/IPool.sol";

/* Libraries *****/
import {sd, sqrt} from "@prb/math/SD59x18.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    struct MintParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint160 currentPrice;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        bool mintLiquidity;
    }

    struct MultiplePoolParams {
        address token0;
        address token1;
        uint256 token0Balance;
        uint256 token1Balance;
        uint160 currentPrice;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        bool mintLiquidity;
    }

    Factory public factory;
    NonfungibleTokenPositionDescriptor public nonfungibleTokenPositionDescriptor;
    Pool public pool;
    ERC20Mock public weth; // ETH
    ERC20Mock public usdc; // USDC

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

        (weth, usdc) = address(_tokenA) < address(_tokenB) ? (_tokenA, _tokenB) : (_tokenB, _tokenA);

        factory = new FactoryScript().run();
        nonfungibleTokenPositionDescriptor = new NonfungibleTokenPositionDescriptorScript().run();

        vm.deal(user, STARTING_BALANCE);
    }

    function divRound(int128 x, int128 y) internal pure returns (int128 result) {
        int128 quot = ABDKMath64x64.div(x, y);
        result = quot >> 64;

        // Check if remainder is greater than 0.5
        if (quot % 2 ** 64 >= 0x8000000000000000) {
            result += 1;
        }
    }

    function nearestUsableTick(int24 tick_, uint24 tickSpacing) internal pure returns (int24 result) {
        result = int24(divRound(int128(tick_), int128(int24(tickSpacing)))) * int24(tickSpacing);

        if (result < TickMath.MIN_TICK) {
            result += int24(tickSpacing);
        } else if (result > TickMath.MAX_TICK) {
            result -= int24(tickSpacing);
        }
    }

    function tick(uint256 price) public pure returns (int24 tick_) {
        tick_ = TickMath.getTickAtSqrtRatio(
            uint160(int160(ABDKMath64x64.sqrt(int128(int256(price << 64))) << (FixedPoint96.RESOLUTION - 64)))
        );
    }

    function tick60(uint256 price) internal pure returns (int24 tick_) {
        tick_ = tick(price);
        tick_ = nearestUsableTick(tick_, 60);
    }

    function sqrtP(uint256 price) public pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick(price));
    }

    function sqrtP60FromTick(int24 tick_) internal pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(nearestUsableTick(tick_, 60));
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

    function encodeCallbackData(address _token0, address _token1, address payer) public pure returns (bytes memory) {
        return abi.encode(IPool.CallbackData({token0: _token0, token1: _token1, payer: payer}));
    }

    function nfts(ExpectedNFT memory nft_) internal pure returns (ExpectedNFT[] memory nfts_) {
        nfts_ = new ExpectedNFT[](1);
        nfts_[0] = nft_;
    }

    function nfts(ExpectedNFT memory nft0, ExpectedNFT memory nft1) internal pure returns (ExpectedNFT[] memory nfts_) {
        nfts_ = new ExpectedNFT[](2);
        nfts_[0] = nft0;
        nfts_[1] = nft1;
    }

    function mintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external virtual override {
        if (shouldTransferInCallback) {
            IPool.CallbackData memory extra = abi.decode(data, (IPool.CallbackData));

            // The msg.sender is the pool contract
            // Transfer the tokens from the payer to the pool
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0Owed);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1Owed);
        }
    }

    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external virtual override {
        IPool.CallbackData memory extra = abi.decode(data, (IPool.CallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0Delta > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1Delta));
        }
    }

    function flashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external virtual override {
        (uint256 amount0, uint256 amount1) = abi.decode(data, (uint256, uint256));

        if (amount0 > 0) {
            weth.transfer(msg.sender, amount0 + fee0);
        }
        if (amount1 > 0) {
            usdc.transfer(msg.sender, amount1 + fee1);
        }

        flashCallbackCalled = true;
    }

    function deployPool(address token0, address token1, uint24 fee, uint256 currentPrice) internal returns (Pool p) {
        p = Pool(factory.createPool(token0, token1, fee));
        p.initialize(sqrtP(currentPrice));
    }

    function setupTestCase(PoolParams memory poolParams)
        public
        virtual
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        // Create pool
        pool = Pool(factory.createPool(address(weth), address(usdc), 1));
        pool.initialize(sqrtP(poolParams.currentPrice));

        shouldTransferInCallback = poolParams.shouldTransferInCallback;

        // Mint tokens to this test contract
        weth.mint(address(this), poolParams.wethBalance);
        usdc.mint(address(this), poolParams.usdcBalance);

        // Add liquidity from liquidity array
        if (poolParams.mintLiquidity) {
            // Approve tokens to the current test contract first
            weth.approve(address(this), poolParams.wethBalance);
            usdc.approve(address(this), poolParams.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < poolParams.liquidity.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = pool.mint(
                    address(this),
                    poolParams.liquidity[i].tickLower,
                    poolParams.liquidity[i].tickUpper,
                    poolParams.liquidity[i].amount,
                    encodeCallbackData(address(weth), address(usdc), address(this))
                );

                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }
    }
}
