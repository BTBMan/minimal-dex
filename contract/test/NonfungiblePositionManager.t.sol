// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* Imports *******/
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {NonfungiblePositionManagerScript} from "../script/NonfungiblePositionManager.s.sol";
import {Pool} from "../src/core/Pool.sol";
import {Factory} from "../src/core/Factory.sol";
import {TestUtils} from "./utils/TestUtils.sol";
import {NonfungiblePositionManager} from "../src/periphery/NonfungiblePositionManager.sol";

/* Interfaces ****/
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";
import {LiquidityMath} from "../src/libraries/LiquidityMath.sol";

/* Libraries *****/

contract NonfungiblePositionManagerTest is Test, TestUtils {
    NonfungiblePositionManager nftPositionManager;

    uint24 public constant FEE = 1;
    uint24 public constant STABLE_FEE = 500;
    uint256 public constant INIT_PRICE = 5000;
    uint256 constant USER_WETH_BALANCE = 10_000 ether;
    uint256 constant USER_USDC_BALANCE = 1_000_000 ether;
    uint256 constant USER_DAI_BALANCE = 1_000_000 ether;
    uint256 constant USER_UNI_BALANCE = 10_000 ether;

    ERC20Mock public dai; // DAI
    ERC20Mock public uni; // UNI

    Pool wethUsdc;
    Pool usdcDai;
    Pool wethUni;

    function setUp() public override {
        super.setUp();

        dai = new ERC20Mock();
        uni = new ERC20Mock();

        nftPositionManager = new NonfungiblePositionManagerScript(address(factory)).run();

        wethUsdc = deployPool(address(weth), address(usdc), FEE, INIT_PRICE);
        usdcDai = deployPool(address(usdc), address(dai), STABLE_FEE, INIT_PRICE);
        wethUni = deployPool(address(weth), address(uni), FEE, INIT_PRICE);

        weth.mint(address(this), USER_WETH_BALANCE);
        usdc.mint(address(this), USER_USDC_BALANCE);
        dai.mint(address(this), USER_DAI_BALANCE);
        uni.mint(address(this), USER_UNI_BALANCE);
        weth.approve(address(nftPositionManager), type(uint256).max);
        usdc.approve(address(nftPositionManager), type(uint256).max);
        dai.approve(address(nftPositionManager), type(uint256).max);
        uni.approve(address(nftPositionManager), type(uint256).max);
    }

    function testInitializeSuccess() public {
        NonfungiblePositionManager positionManager = new NonfungiblePositionManagerScript(address(factory)).run();

        uint160 initializedSqrtPriceX96 = sqrtP(5000);

        pool = Pool(
            positionManager.createAndInitializePoolIfNecessary(address(weth), address(usdc), 1, initializedSqrtPriceX96)
        );

        (uint160 sqrtPriceX96,,,,) = pool.slot0();

        assertEq(sqrtPriceX96, initializedSqrtPriceX96);
    }

    function liquidity(INonfungiblePositionManager.MintParams memory params, uint256 currentPrice)
        internal
        pure
        returns (uint128 liquidity_)
    {
        liquidity_ = LiquidityMath.getLiquidityForAmounts(
            sqrtP(currentPrice),
            sqrtP60FromTick(params.tickLower),
            sqrtP60FromTick(params.tickUpper),
            params.amount0Desired,
            params.amount1Desired
        );
    }

    function liquidity(INonfungiblePositionManager.IncreaseLiquidityParams memory params, uint256 currentPrice)
        internal
        view
        returns (uint128 liquidity_)
    {
        (, int24 lowerTick, int24 upperTick) = nftPositionManager._positions(params.tokenId);

        liquidity_ = LiquidityMath.getLiquidityForAmounts(
            sqrtP(currentPrice),
            sqrtP60FromTick(lowerTick),
            sqrtP60FromTick(upperTick),
            params.amount0Desired,
            params.amount1Desired
        );
    }

    function mintAndAddParamsToTicks(
        INonfungiblePositionManager.MintParams memory mint,
        INonfungiblePositionManager.IncreaseLiquidityParams memory add,
        uint256 currentPrice
    ) internal view returns (ExpectedTickShort[2] memory ticks) {
        uint128 liqMint = liquidity(mint, currentPrice);
        uint128 liqAdd = liquidity(add, currentPrice);
        uint128 liq = liqMint + liqAdd;

        ticks[0] = ExpectedTickShort({
            tick: mint.tickLower, initialized: true, liquidityGross: liq, liquidityNet: int128(liq)
        });
        ticks[1] = ExpectedTickShort({
            tick: mint.tickUpper, initialized: true, liquidityGross: liq, liquidityNet: -int128(liq)
        });
    }

    function mintAndRemoveParamsToTicks(
        INonfungiblePositionManager.MintParams memory mint,
        INonfungiblePositionManager.DecreaseLiquidityParams memory remove,
        uint256 currentPrice
    ) internal pure returns (ExpectedTickShort[2] memory ticks) {
        uint128 liqMint = liquidity(mint, currentPrice);
        uint128 liq = liqMint - remove.liquidity;

        ticks[0] = ExpectedTickShort({
            tick: mint.tickLower, initialized: true, liquidityGross: liq, liquidityNet: int128(liq)
        });
        ticks[1] = ExpectedTickShort({
            tick: mint.tickUpper, initialized: true, liquidityGross: liq, liquidityNet: -int128(liq)
        });
    }

    function testPositionManagerMintSuccess() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            recipient: address(this),
            tickLower: tick(4540),
            tickUpper: tick(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0
        });
        (uint256 tokenId, uint128 liq,,) = nftPositionManager.mint(mintParams);

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        assertMany(
            ExpectedMany({
                pool: wethUsdc,
                tokens: [weth, usdc],
                liquidity: liq,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                position: ExpectedPositionShort({
                    owner: address(nftPositionManager),
                    ticks: [mintParams.tickLower, mintParams.tickUpper],
                    liquidity: liq,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                userBalances: [USER_WETH_BALANCE - expectedAmount0, USER_USDC_BALANCE - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                ticks: [
                    ExpectedTickShort({
                        tick: mintParams.tickLower, initialized: true, liquidityGross: liq, liquidityNet: int128(liq)
                    }),
                    ExpectedTickShort({
                        tick: mintParams.tickUpper, initialized: true, liquidityGross: liq, liquidityNet: -int128(liq)
                    })
                ],
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );

        assertNFTs(
            ExpectedNFTs({
                nft: nftPositionManager,
                owner: address(this),
                tokens: nfts(
                    ExpectedNFT({
                        id: tokenId,
                        pool: address(wethUsdc),
                        lowerTick: mintParams.tickLower,
                        upperTick: mintParams.tickUpper
                    })
                )
            })
        );
    }

    function testPositionManagerMintOutOfSlippage() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            recipient: address(this),
            tickLower: tick(4540),
            tickUpper: tick(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 1 ether,
            amount1Min: 5000 ether
        });

        uint256 expectedAmount0 = 0.987877509829196393 ether;
        uint256 expectedAmount1 = 4999.999999999999999998 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                INonfungiblePositionManager.SlippageCheckFailed.selector, expectedAmount0, expectedAmount1
            )
        );
        nftPositionManager.mint(mintParams);
    }

    function testPositionManagerMintMultiple() public {
        (uint256 tokenId0,,,) = nftPositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: address(weth),
                token1: address(usdc),
                fee: FEE,
                recipient: address(this),
                tickLower: tick(4540),
                tickUpper: tick(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        (uint256 tokenId1,,,) = nftPositionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: address(usdc),
                token1: address(dai),
                fee: STABLE_FEE,
                recipient: address(this),
                tickLower: -520, // 0.95
                tickUpper: 490, // 1.05
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        assertEq(tokenId0, 0, "invalid token id");
        assertEq(tokenId1, 1, "invalid token id");

        assertNFTs(
            ExpectedNFTs({
                nft: nftPositionManager,
                owner: address(this),
                tokens: nfts(
                    ExpectedNFT({id: tokenId0, pool: address(wethUsdc), lowerTick: tick(4540), upperTick: tick(5500)}),
                    ExpectedNFT({id: tokenId1, pool: address(usdcDai), lowerTick: -520, upperTick: 490})
                )
            })
        );
    }

    function testIncreaseLiquidity() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            recipient: address(this),
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            tickLower: tick60(4545),
            tickUpper: tick60(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0
        });
        (uint256 tokenId,,,) = nftPositionManager.mint(mintParams);

        INonfungiblePositionManager.IncreaseLiquidityParams memory addParams =
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: 0.5 ether,
                amount1Desired: 2500 ether,
                amount0Min: 0.4 ether,
                amount1Min: 2000 ether
            });

        (uint128 liquidityAdded, uint256 amount0Added, uint256 amount1Added) =
            nftPositionManager.increaseLiquidity(addParams);

        assertEq(tokenId, 0, "invalid token id");
        assertEq(liquidityAdded, liquidity(addParams, INIT_PRICE), "invalid added liquidity");
        assertEq(amount0Added, 0.493746089868300255 ether, "invalid added token0 amount");
        assertEq(amount1Added, 2499.999999999999999998 ether, "invalid added token1 amount");

        (uint256 expectedAmount0, uint256 expectedAmount1) = (1.481238269604900764 ether, 7499.999999999999999997 ether);

        assertMany(
            ExpectedMany({
                pool: wethUsdc,
                tokens: [weth, usdc],
                liquidity: liquidity(mintParams, INIT_PRICE) + liquidity(addParams, INIT_PRICE),
                sqrtPriceX96: sqrtP(INIT_PRICE),
                tick: tick(INIT_PRICE),
                fees: [uint256(0), 0],
                userBalances: [USER_WETH_BALANCE - expectedAmount0, USER_USDC_BALANCE - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(nftPositionManager),
                    ticks: [mintParams.tickLower, mintParams.tickUpper],
                    liquidity: liquidity(mintParams, INIT_PRICE) + liquidity(addParams, INIT_PRICE),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintAndAddParamsToTicks(mintParams, addParams, INIT_PRICE),
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );

        assertNFTs(
            ExpectedNFTs({
                nft: nftPositionManager,
                owner: address(this),
                tokens: nfts(
                    ExpectedNFT({
                        id: tokenId,
                        pool: address(wethUsdc),
                        lowerTick: mintParams.tickLower,
                        upperTick: mintParams.tickUpper
                    })
                )
            })
        );
    }

    function testRemoveLiquidity() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            recipient: address(this),
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            tickLower: tick60(4545),
            tickUpper: tick60(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0
        });
        (uint256 tokenId,,,) = nftPositionManager.mint(mintParams);

        INonfungiblePositionManager.DecreaseLiquidityParams memory removeParams =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId, liquidity: liquidity(mintParams, INIT_PRICE) / 2, amount0Min: 0, amount1Min: 0
            });

        (uint256 amount0Removed, uint256 amount1Removed) = nftPositionManager.decreaseLiquidity(removeParams);

        assertEq(tokenId, 0, "invalid token id");
        assertEq(amount0Removed, 0.493746089868300254 ether, "invalid removed token0 amount");
        assertEq(amount1Removed, 2499.999999999999999997 ether, "invalid removed token1 amount");

        (uint256 expectedAmount0, uint256 expectedAmount1) = (0.987492179736600509 ether, 4999.999999999999999999 ether);

        assertMany(
            ExpectedMany({
                pool: wethUsdc,
                tokens: [weth, usdc],
                liquidity: liquidity(mintParams, INIT_PRICE) - removeParams.liquidity,
                sqrtPriceX96: sqrtP(INIT_PRICE),
                tick: tick(INIT_PRICE),
                fees: [uint256(0), 0],
                userBalances: [USER_WETH_BALANCE - expectedAmount0, USER_USDC_BALANCE - expectedAmount1],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(nftPositionManager),
                    ticks: [mintParams.tickLower, mintParams.tickUpper],
                    liquidity: liquidity(mintParams, INIT_PRICE) - removeParams.liquidity,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(amount0Removed), uint128(amount1Removed)]
                }),
                ticks: mintAndRemoveParamsToTicks(mintParams, removeParams, INIT_PRICE),
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );

        assertNFTs(
            ExpectedNFTs({
                nft: nftPositionManager,
                owner: address(this),
                tokens: nfts(
                    ExpectedNFT({
                        id: tokenId,
                        pool: address(wethUsdc),
                        lowerTick: mintParams.tickLower,
                        upperTick: mintParams.tickUpper
                    })
                )
            })
        );
    }

    function testCollect() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            recipient: address(this),
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            tickLower: tick60(4545),
            tickUpper: tick60(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0
        });
        (uint256 tokenId,,,) = nftPositionManager.mint(mintParams);

        INonfungiblePositionManager.DecreaseLiquidityParams memory removeParams =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId, liquidity: liquidity(mintParams, INIT_PRICE) / 2, amount0Min: 0, amount1Min: 0
            });

        (uint256 amount0Removed, uint256 amount1Removed) = nftPositionManager.decreaseLiquidity(removeParams);

        (uint256 amount0Collected, uint256 amount1Collected) = nftPositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(amount0Removed),
                amount1Max: uint128(amount1Removed)
            })
        );

        console.log("amount0Removed", amount0Removed);
        console.log("amount1Removed", amount1Removed);
        console.log("amount0Collected", amount0Collected);
        console.log("amount1Collected", amount1Collected);

        assertEq(tokenId, 0, "invalid token id");
        assertEq(amount0Collected, 0.493539174222068722 ether, "invalid removed token0 amount");
        assertEq(amount1Collected, 2499.999999999999999997 ether, "invalid removed token1 amount");

        (uint256 expectedAmount0, uint256 expectedAmount1) = (0.987078348444137445 ether, 5000 ether);

        assertMany(
            ExpectedMany({
                pool: wethUsdc,
                tokens: [weth, usdc],
                liquidity: liquidity(mintParams, INIT_PRICE) - removeParams.liquidity,
                sqrtPriceX96: sqrtP(INIT_PRICE),
                tick: tick(INIT_PRICE),
                fees: [uint256(0), 0],
                userBalances: [
                    USER_WETH_BALANCE - expectedAmount0 + amount0Collected,
                    USER_USDC_BALANCE - expectedAmount1 + amount1Collected
                ],
                poolBalances: [expectedAmount0 - amount0Collected, expectedAmount1 - amount1Collected],
                position: ExpectedPositionShort({
                    owner: address(nftPositionManager),
                    ticks: [mintParams.tickLower, mintParams.tickUpper],
                    liquidity: liquidity(mintParams, INIT_PRICE) - removeParams.liquidity,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintAndRemoveParamsToTicks(mintParams, removeParams, INIT_PRICE),
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );

        assertNFTs(
            ExpectedNFTs({
                nft: nftPositionManager,
                owner: address(this),
                tokens: nfts(
                    ExpectedNFT({
                        id: tokenId,
                        pool: address(wethUsdc),
                        lowerTick: mintParams.tickLower,
                        upperTick: mintParams.tickUpper
                    })
                )
            })
        );
    }

    function testBurn() public {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            recipient: address(this),
            token0: address(weth),
            token1: address(usdc),
            fee: FEE,
            tickLower: tick60(4545),
            tickUpper: tick60(5500),
            amount0Desired: 1 ether,
            amount1Desired: 5000 ether,
            amount0Min: 0,
            amount1Min: 0
        });
        (uint256 tokenId,,,) = nftPositionManager.mint(mintParams);

        INonfungiblePositionManager.DecreaseLiquidityParams memory removeParams =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId, liquidity: liquidity(mintParams, INIT_PRICE), amount0Min: 0, amount1Min: 0
            });
        (uint256 amount0Removed, uint256 amount1Removed) = nftPositionManager.decreaseLiquidity(removeParams);

        nftPositionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: uint128(amount0Removed),
                amount1Max: uint128(amount1Removed)
            })
        );

        nftPositionManager.burn(tokenId);

        assertEq(tokenId, 0, "invalid token id");

        assertMany(
            ExpectedMany({
                pool: wethUsdc,
                tokens: [weth, usdc],
                liquidity: 0,
                sqrtPriceX96: sqrtP(INIT_PRICE),
                tick: tick(INIT_PRICE),
                fees: [uint256(0), 0],
                userBalances: [USER_WETH_BALANCE - 1, USER_USDC_BALANCE - 1],
                poolBalances: [uint256(1), 1],
                position: ExpectedPositionShort({
                    owner: address(nftPositionManager),
                    ticks: [mintParams.tickLower, mintParams.tickUpper],
                    liquidity: 0,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintAndRemoveParamsToTicks(mintParams, removeParams, INIT_PRICE),
                observation: ExpectedObservationShort({index: 0, timestamp: 1, tickCumulative: 0, initialized: true})
            })
        );

        assertEq(nftPositionManager.balanceOf(address(this)), 0);

        // vm.expectRevert(ERC721NonexistentToken.selector, tokenId);
        // nftPositionManager.ownerOf(tokenId);
    }
}
