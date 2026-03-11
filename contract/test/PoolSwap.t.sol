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

contract PoolSwapTest is Test, IPoolTest, IMintCallback, ISwapCallback {
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

    function mintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        if (shouldTransferInCallback) {
            INonfungiblePositionManager.MintCallbackData memory extra =
                abi.decode(data, (INonfungiblePositionManager.MintCallbackData));

            // The msg.sender is the pool contract
            // Transfer the tokens from the payer to the pool
            token0.transferFrom(extra.payer, msg.sender, amount0Owed);
            token1.transferFrom(extra.payer, msg.sender, amount1Owed);
        }
    }

    function swapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        ISwapRouter.SwapCallbackData memory extra = abi.decode(data, (ISwapRouter.SwapCallbackData));

        // The msg.sender is the pool contract, only one of these tokens can be transferred
        // Transfer the tokens from the payer to the pool
        if (amount0Delta > 0) {
            token0.transferFrom(extra.payer, msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            token1.transferFrom(extra.payer, msg.sender, uint256(amount1Delta));
        }
    }

    function testSwapBuyETHNotEnoughLiquidity() public {
        PoolParams memory poolParams = PoolParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            tickCurrent: 85176,
            tickLower: 84222,
            tickUpper: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240, // ≈ (1 ETH = 5000 USDC)
            shouldTransferInCallback: true,
            mintLiquidity: true
        });

        setupTestCase(poolParams);
    }
}
