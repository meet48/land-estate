// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Estate contract.
 */
interface IEstate {
    function mint(address to, string calldata metadata) external returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
}

/**
 * @dev Land storage.
 */
contract LandStorage {
    // Mint role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Base uri.
    string public baseURI;
    
    // total amount of tokens
    uint256 public totalSupply;

    // Estate contract.
    IEstate public Estate;

    // Mapping from token ID to data.
    mapping(uint256 => string) internal _assetData;

    // Mapping from token ID to operator address.
    mapping (uint256 => address) public updateOperator;

    // Mapping from owner to manager approvals.
    mapping(address => mapping(address => bool)) public updateManager;

    // Mapping from owner to list of owned token IDs.
    mapping(address => uint256[]) internal _ownedTokens;

    // Mapping from token ID to index of the _ownedTokens list.
    mapping(uint256 => uint256) internal _ownedTokensIndex;

    /**
     * @dev Emitted when set the operator of the owner.
     */
    event UpdateManager(address indexed owner, address indexed operator, address indexed caller, bool _approved);
    
    /**
     * @dev Emitted when set the operator of the tokenId.
     */
    event UpdateOperator(uint256 indexed tokenId, address indexed operator);
    
    /**
     * @dev Emitted when set the data of the tokenId.
     */
    event UpdateLandData(uint256 indexed tokenId, address indexed operator, string data);
    
    /**
     * @dev Emitted when set the estate contract.
     */
    event SetEstateContract(address indexed registry);
}
