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

    mapping(uint256 tokenId => Position) public _positions;

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
    modifier isAuthorizedForToken(uint256 tokenId) {
        if (!_isAuthorized(_ownerOf(tokenId), msg.sender, tokenId)) {
            revert NotAuthorized();
        }
        _;
    }

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

    function mint(MintParams calldata params)
        public
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        IPool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
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
        returns (uint128 liquidity, uint256 amount0, uint256 amount1, IPool pool)
    {
        // Compute the pool contract address
        PoolAddress.PoolKey memory poolKey = PoolAddress.getPoolKey(params.token0, params.token1, params.fee);
        pool = IPool(PoolAddress.computeAddress(factory, poolKey));

        // Get current sqrt price of the current pool
        (uint160 sqrtPriceX96,,,,) = pool.slot0();
        // Calculate tickLower/tickUpper sqrt price
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        // Calculate liquidity
        liquidity = LiquidityMath.getLiquidityForAmounts(
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
    function increaseLiquidity(IncreaseLiquidityParams memory params)
        external
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        Position memory position = _positions[params.tokenId];

        // Do not allow increasing liquidity for a non-existent position
        if (position.pool == address(0)) {
            revert PositionDoesNotExist();
        }

        (liquidity, amount0, amount1,) = addLiquidity(
            AddLiquidityParams({
                token0: IPool(position.pool).token0(),
                token1: IPool(position.pool).token1(),
                fee: IPool(position.pool).fee(),
                recipient: address(this),
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );

        emit IncreaseLiquidity(params.tokenId, amount0, amount1);
    }

    /**
     * @notice Decrease liquidity for a given position
     */
    function decreaseLiquidity(DecreaseLiquidityParams memory params)
        external
        isAuthorizedForToken(params.tokenId)
        returns (uint256 amount0, uint256 amount1)
    {
        Position memory position = _positions[params.tokenId];

        // Do not allow decreasing liquidity for a non-existent position
        if (position.pool == address(0)) {
            revert PositionDoesNotExist();
        }

        IPool pool = IPool(position.pool);

        // Get position info of the pool
        (uint128 availableLiquidity,,,,) = pool.positions(poolPositionKey(position));
        if (params.liquidity > availableLiquidity) {
            revert InsufficientLiquidity();
        }

        (amount0, amount1) = pool.burn(position.tickLower, position.tickUpper, params.liquidity);

        if (params.amount0Min > amount0 || params.amount1Min > amount1) {
            revert SlippageCheckFailed(amount0, amount1);
        }

        emit DecreaseLiquidity(params.tokenId, amount0, amount1);
    }

    /**
     * @notice Get owed token amount for a given position
     */
    function collect(CollectParams memory params)
        external
        isAuthorizedForToken(params.tokenId)
        returns (uint256 amount0, uint256 amount1)
    {
        Position memory position = _positions[params.tokenId];

        // Do not allow decreasing liquidity for a non-existent position
        if (position.pool == address(0)) {
            revert PositionDoesNotExist();
        }

        IPool pool = IPool(position.pool);
        (,,, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(poolPositionKey(position));

        (uint128 amount0Collect, uint128 amount1Collect) = (
            params.amount0Max > tokensOwed0 ? tokensOwed0 : params.amount0Max,
            params.amount1Max > tokensOwed1 ? tokensOwed1 : params.amount1Max
        );

        (amount0, amount1) =
            pool.collect(params.recipient, position.tickLower, position.tickUpper, amount0Collect, amount1Collect);

        emit Collect(params.tokenId, params.recipient, amount0, amount1);
    }

    /**
     * @notice Burn a NFT
     */
    function burn(uint256 tokenId) external isAuthorizedForToken(tokenId) {
        Position memory position = _positions[tokenId];

        // Do not allow decreasing liquidity for a non-existent position
        if (position.pool == address(0)) {
            revert PositionDoesNotExist();
        }

        IPool pool = IPool(position.pool);
        (uint128 liquidity,,, uint128 tokensOwed0, uint128 tokensOwed1) = pool.positions(poolPositionKey(position));

        if (liquidity > 0 || tokensOwed0 > 0 || tokensOwed1 > 0) {
            revert NotCleared();
        }

        delete _positions[tokenId];
        _burn(tokenId);
    }

    /**
     * @notice Get the position key of the pool
     */
    function poolPositionKey(Position memory position) internal view returns (bytes32) {
        // We use the NonfungiblePositionManager to manage the position, so all the position's owner is the current contract
        return keccak256(abi.encodePacked(address(this), position.tickLower, position.tickUpper));
    }

    // Internal view  //////////////////

    // Internal pure  //////////////////

    ////////////////////////////////////
    // Private functions              //
    ////////////////////////////////////

    // Private view ////////////////////

    // Private pure ////////////////////
}
