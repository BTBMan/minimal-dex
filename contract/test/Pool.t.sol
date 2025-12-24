// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {Pool} from "../src/core/Pool.sol";

/* Interfaces ****/
import {IPoolTest} from "./interfaces/IPoolTest.sol";
import {IMintCallback} from "../src/interfaces/callback/IMintCallback.sol";

/* Libraries *****/
import {Position} from "../src/libraries/Position.sol";

contract PoolTest is Test, IPoolTest, IMintCallback {
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

        // Create pool
        pool = new Pool(address(token0), address(token1), poolParams.currentSqrtP, poolParams.tickCurrent);

        shouldTransferInCallback = poolParams.shouldTransferInCallback;

        // Mint liquidity if necessary
        if (poolParams.mintLiquidity) {
            (poolBalance0, poolBalance1) =
                pool.mint(address(this), poolParams.tickLower, poolParams.tickUpper, poolParams.liquidity);
        }
    }

    function mintCallback(uint256 amount0, uint256 amount1) external override {
        if (shouldTransferInCallback) {
            // The msg.sender is the pool contract
            token0.transfer(msg.sender, amount0);
            token1.transfer(msg.sender, amount1);
        }
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
}
