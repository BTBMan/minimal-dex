// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/* Imports *******/
import {Pool} from "../core/Pool.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

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
import {PoolAddress} from "../libraries/PoolAddress.sol";

/**
 * @title  NonfungiblePositionManager
 * @author BTBMan
 * @notice This is a NonfungiblePositionManager Contract
 */
contract NonfungiblePositionManager is INonfungiblePositionManager, IMintCallback, ERC721 {
    ////////////////////////////////////
    // Type declarations              //
    ////////////////////////////////////

    ////////////////////////////////////
    // State variables                //
    ////////////////////////////////////
    // The address of the factory contract
    address public immutable factory;

    mapping(uint256 tokenId => Position) private _positions;

    // The id of the next token
    uint176 private _nextId;

    ////////////////////////////////////
    // Events                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Errors                         //
    ////////////////////////////////////

    ////////////////////////////////////
    // Modifiers                      //
    ////////////////////////////////////

    constructor(address _factory) ERC721("Uniswap V3 Positions NFT", "UNI-V3-POS") {
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

    function mint(MintParams calldata params) public returns (uint256 amount0, uint256 amount1, uint256 tokenId) {
        IPool pool;
        (amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                recipient: address(this),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );

        _mint(params.recipient, (tokenId = _nextId++));

        _positions[tokenId] = Position({pool: address(pool), tickLower: params.tickLower, tickUpper: params.tickUpper});

        emit IncreaseLiquidity(tokenId, amount0, amount1);
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
            (uint160 sqrtPriceX96Existing,,,,) = IPool(pool).slot0();
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return "";
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
    // Liquidity management functions
    function addLiquidity(AddLiquidityParams memory params)
        internal
        returns (uint256 amount0, uint256 amount1, IPool pool)
    {
        // Compute the pool contract address
        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee});
        pool = IPool(PoolAddress.computeAddress(factory, poolKey));

        // Get current sqrt price of the current pool
        (uint160 sqrtPriceX96,,,,) = pool.slot0();
        // Calculate tickLower/tickUpper sqrt price
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        // Calculate liquidity
        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96, sqrtPriceLowerX96, sqrtPriceUpperX96, params.amount0Desired, params.amount1Desired
        );

        // Mint(create position)
        (amount0, amount1) = pool.mint(
            params.recipient,
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

    /**
     * @notice Increase liquidity for a given position
     * @dev Do not mint nft repeatedly
     */
    function increaseLiquidity(IncreaseLiquidityParams memory params) external {
        Position memory position = _positions[params.tokenId];
    }

    /**
     * @notice Decrease liquidity for a given position
     */
    function decreaseLiquidity() external {
        //
    }

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
