// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Land interface.
 */
interface ILAND is IERC721{
    /**
     * @dev TokenId is converted to coordinates.
     */    
    function decodeTokenId(uint value) external pure returns (int, int);
    
    /**
     * @dev Update land data.
     */    
    function updateLandData(int x, int y, string calldata data) external;
    
    /**
     * @dev Set the operator of the tokenId.
     */    
    function setUpdateOperator(uint256 tokenId, address operator) external;
    
    /**
     * @dev Batch set the operator of the tokenId.
     */    
    function setManyUpdateOperator(uint256[] calldata _tokenIds, address _operator) external;
    
    /**
     * @dev Returns the operator for the land id.
     */    
    function updateOperator(uint256 landId) external returns (address);
}

/**
 * @dev Estate storage.
 */
contract EstateStorage {

    // Land.
    ILAND public Land;

    // total amount of tokens
    uint256 public totalSupply;
    
    // Mapping from token ID to land ids.
    mapping(uint256 => uint256[]) public estateLandIds;

    // Mapping from token id to index of estateLandIds list.
    mapping(uint256 => mapping(uint256 => uint256)) internal _estateLandIndex;

    // Mapping from land id to token id.
    mapping(uint256 => uint256) public landIdEstate;

    // Mapping from token ID to data.
    mapping(uint256 => string) public estateData;

    // Mapping from token ID to operator address.
    mapping (uint256 => address) public updateOperator;

    // Mapping from owner to manager approvals.
    mapping(address => mapping(address => bool)) public updateManager;

    // Mapping from owner to list of owned token ids.
    mapping(address => uint256[]) internal _ownedTokens;

    // Mapping from token ID to index of the _ownedTokens list.
    mapping(uint256 => uint256) internal _ownedTokensIndex;


    /**
     * @dev Emitted when contract received landId.
     */    
    event ReceiveLand(address operator, address from, uint256 landId, uint256 estateId);    

    /**
     * @dev Emitted when set the land contract.
     */    
    event SetLandContract(address indexed registry);
    
    /**
     * @dev Emitted when create estateId.
     */    
    event CreateEstate(address indexed owner, uint256 indexed estateId, string data);
    
    /**
     * @dev Emitted when set the operator of the owner.
     */    
    event UpdateManager(address indexed owner, address indexed operator, address indexed caller, bool approved);
    
    /**
     * @dev Emitted when set the operator of the estateId.
     */    
    event UpdateOperator(uint256 indexed estateId, address indexed operator);
    
    /**
     * @dev Emitted when set the data of the estateId.
     */    
    event UpdateData(uint256 indexed estateId, address indexed owner, address indexed operator, string data);
    
    /**
     * @dev Emitted when add landId to estateId.
     */    
    event AddLand(uint256 indexed estateId, uint256 indexed landId);
        
    /**
     * @dev Emitted when remove landId from estateId.
     */    
    event RemoveLand(uint256 indexed estateId, uint256 indexed landId, address indexed to);


}
