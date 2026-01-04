// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Pool} from "../src/core/Pool.sol";

/* Interfaces ****/
import {IPoolTest} from "./interfaces/IPoolTest.sol";
import {IMintCallback} from "../src/interfaces/callback/IMintCallback.sol";
import {ISwapCallback} from "../src/interfaces/callback/ISwapCallback.sol";
import {INonfungiblePositionManager} from "./../src/interfaces/INonfungiblePositionManager.sol";
import {ISwapRouter} from "./../src/interfaces/ISwapRouter.sol";

/* Libraries *****/

contract PoolTest is Test, IPoolTest, IMintCallback, ISwapCallback {
    Pool public pool;
    ERC20Mock public token0; // ETH
    ERC20Mock public token1; // USDC

    bool public shouldTransferInCallback;

    address public user = makeAddr("user");

    uint256 public constant STARTING_BALANCE = 1 ether;

    function setUp() public {
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();

        vm.deal(user, STARTING_BALANCE);
    }

    function setupTestCase(PoolParams memory poolParams) public returns (uint256 poolBalance0, uint256 poolBalance1) {
        // Mint tokens to this test contract
        token0.mint(address(this), poolParams.wethBalance);
        token1.mint(address(this), poolParams.usdcBalance);

        // Approve tokens to the current test contract
        token0.approve(address(this), poolParams.wethBalance);
        token1.approve(address(this), poolParams.usdcBalance);

        // Create pool
        pool = new Pool(address(token0), address(token1), poolParams.currentSqrtP, poolParams.tickCurrent);

        shouldTransferInCallback = poolParams.shouldTransferInCallback;

        // Mint liquidity if necessary
        if (poolParams.mintLiquidity) {
            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                poolParams.tickLower,
                poolParams.tickUpper,
                poolParams.liquidity,
                abi.encode(token0, token1, address(this))
            );
        }
    }

    function mintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external override {
        if (shouldTransferInCallback) {
            INonfungiblePositionManager.MintCallbackData memory extra =
                abi.decode(data, (INonfungiblePositionManager.MintCallbackData));

            // The msg.sender is the pool contract
            // Transfer the tokens from the payer to the pool
            token0.transferFrom(extra.payer, msg.sender, amount0);
            token1.transferFrom(extra.payer, msg.sender, amount1);
        }
    }

    function swapCallback(int256 amount0, int256 amount1, bytes calldata data) external override {
        ISwapRouter.SwapCallbackData memory extra = abi.decode(data, (ISwapRouter.SwapCallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0 > 0) {
            token0.transferFrom(extra.payer, msg.sender, uint256(amount0));
        }
        if (amount1 > 0) {
            token1.transferFrom(extra.payer, msg.sender, uint256(amount1));
        }
    }

    function testMath() public {
        uint256 a = 2;
        uint256 b = 3;
        uint256 c = 4;

        // uint256 result = mulDiv(a, b, c);
        // console.log(result);
        // console.log(ceil(d));
        // console.log(a / b);
    }

    function testMintSuccess() public {
        PoolParams memory poolParams = PoolParams({
            wethBalance: 0.99897661834742528 ether,
            // wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            tickCurrent: 85176,
            tickLower: 84222,
            tickUpper: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        // Balance
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        assertEq(poolBalance0, poolParams.wethBalance, "Incorrect token0 deposited amount");
        assertEq(poolBalance1, poolParams.usdcBalance, "Incorrect token1 deposited amount");

        assertEq(token0.balanceOf(address(pool)), poolParams.wethBalance);
        assertEq(token1.balanceOf(address(pool)), poolParams.usdcBalance);

        // Position
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), poolParams.tickLower, poolParams.tickUpper));
        uint128 positionLiquidity = pool.positions(positionKey);

        assertEq(positionLiquidity, poolParams.liquidity);

        // Tick
        (bool tickLowerInitialized, uint128 tickLowerLiquidity) = pool.ticks(poolParams.tickLower);
        (bool tickUpperInitialized, uint128 tickUpperLiquidity) = pool.ticks(poolParams.tickUpper);

        assertEq(tickLowerInitialized, true);
        assertEq(tickUpperInitialized, true);
        assertEq(tickLowerLiquidity, poolParams.liquidity);
        assertEq(tickUpperLiquidity, poolParams.liquidity);

        // Slot0
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, poolParams.currentSqrtP);
        assertEq(tick, poolParams.tickCurrent);

        // Liquidity
        uint128 liquidity = pool.liquidity();
        assertEq(liquidity, poolParams.liquidity);
    }

    function testSwapBuyETH() public {
        PoolParams memory poolParams = PoolParams({
            wethBalance: 0.99897661834742528 ether,
            // wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            tickCurrent: 85176,
            tickLower: 84222,
            tickUpper: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        // Balance
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(poolParams);

        // Mint 42 USDC to the test contract
        token1.mint(address(this), 42 ether);

        // Approve tokens to the current test contract
        token1.approve(address(this), 42 ether);

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));

        // Swap
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(address(this), abi.encode(token0, token1, address(this)));

        // Check swap amount
        assertEq(amount0Delta, -0.008396714242162444 ether);
        assertEq(amount1Delta, 42 ether);

        // Check user(the test contract) balance
        assertEq(token0.balanceOf(address(this)), uint256(userBalance0Before - amount0Delta));
        assertEq(token1.balanceOf(address(this)), 0);

        // Check pool balance
        assertEq(token0.balanceOf((address(pool))), uint256(int256(poolBalance0) + amount0Delta));
        assertEq(token1.balanceOf((address(pool))), uint256(int256(poolBalance1) + amount1Delta));

        // Check sqrtPrice, tick and liquidity
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(sqrtPriceX96, 5604469350942327889444743441197);
        assertEq(tick, 85184);
        assertEq(pool.liquidity(), 1517882343751509868544);
    }
}
