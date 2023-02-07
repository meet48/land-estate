// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library LibInt {

    uint256 constant clearLow = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant clearHigh = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant factor = 0x100000000000000000000000000000000;


    /**
     * @dev The coordinates are converted to tokenId.
     * @param {int} x X coordinate.
     * @param {int} y Y coordinate.
     * @return {tokenId}.
     */    
    function _encodeTokenId(int x, int y) public pure returns (uint) {
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );

        uint256 x1;
        unchecked {
            x1 = uint(x) * factor;
        }

        return (x1 & clearLow) | (uint(y) & clearHigh);
    }

    /**
     * @dev TokenId is converted to coordinates.
     */      
    function _decodeTokenId(uint value) public pure returns (int x, int y) {
        x = expandNegative128BitCast((value & clearLow) >> 128);
        y = expandNegative128BitCast(value & clearHigh);
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
    }
    
    function expandNegative128BitCast(uint value) public pure returns (int) {
        if (value & (1<<127) != 0) {
            return int(value | clearLow);
        }
        return int(value);
    }



}