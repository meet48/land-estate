// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library LibString {

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */    
    function getTokenURL(string memory baseURI , uint256 tokenId) public pure returns(string memory) {
        return string(abi.encodePacked(baseURI , toString(tokenId) , ".json"));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */    
    function toString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


}