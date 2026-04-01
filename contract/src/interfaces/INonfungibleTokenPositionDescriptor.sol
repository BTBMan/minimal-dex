// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {INonfungiblePositionManager} from "./INonfungiblePositionManager.sol";

interface INonfungibleTokenPositionDescriptor {
    function tokenURI(INonfungiblePositionManager positionManager, uint256 tokenId)
        external
        view
        returns (string memory);
}
