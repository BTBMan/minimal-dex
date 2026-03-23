// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {BytesLib} from "@bytes/utils/BytesLib.sol";

library BytesLibExt {
    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");

        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toInt24(bytes memory _bytes, uint256 _start) internal pure returns (int24) {
        require(_bytes.length >= _start + 3, "toInt24_outOfBounds");

        int24 tempInt;

        assembly {
            tempInt := mload(add(add(_bytes, 0x3), _start))
        }

        return tempInt;
    }
}

library Path {
    using BytesLib for bytes;
    using BytesLibExt for bytes;

    // The size of a address in bytes
    uint256 private constant ADDR_SIZE = 20;
    // The size of a tickSpacing in bytes
    uint256 private constant FEE_SIZE = 3;
    // The size of a offset of the next token address in bytes
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    // The size of a offset of the encode pool key in bytes
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    // The minimum length of a path that contains two or more pools
    // The minimum length of a multiple pool path includes three tokens at least
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /**
     * @notice Returns the number of pools in the path
     * @param path The path to get the pool counts from
     * @return The pool counts
     */
    function numPools(bytes memory path) internal pure returns (uint256) {
        return (path.length - ADDR_SIZE) / NEXT_OFFSET;
    }

    /**
     * @notice Returns true if the path contains multiple pools
     */
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /**
     * @notice Skip the token + tickSpacing form the path and returns the remainder
     */
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }

    /**
     * @notice Returns the first pool of the path
     */
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        // address + tickSpacing + address
        return path.slice(0, POP_OFFSET);
    }

    /**
     * @notice Decode the first pool from path
     */
    function decodeFirstPool(bytes memory path) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }
}
