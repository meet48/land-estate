// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Access.sol";
import "./LandStorage.sol";
import "./LibString.sol";
import "./LibInt.sol";

/**
 * @dev Land
 */
contract Land is ERC721 , Ownable , Access , LandStorage {
    using LibString for string;
    using LibInt for int;
    using LibInt for uint;

    constructor() ERC721("Meet48 LAND", "LAND") {
        _grantRole(MINTER_ROLE, _msgSender());
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer ownership.
     */    
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0), "zero address");
        _transferOwnership(_newOwner);
        
        // Set the permissions.
        _grantRole(MINTER_ROLE, _newOwner);
        
        // Revoke permissions.
        _revokeRole(MINTER_ROLE, _msgSender());
    }

    /**
     * @dev Set the permissions.
     */    
    function grantRole(bytes32 role , address account) external onlyOwner {
        _grantRole(role , account);
    }

    /**
     * @dev Revoke permissions.
     */    
    function revokeRole(bytes32 role, address account) external onlyOwner {
        _revokeRole(role , account);
    }

    /**
     * @dev Mint
     */    
    function mint(address to , int x , int y) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller unauthorized");
        require(to != address(0) , "to zero address");
    
        uint256 tokenId = _encodeTokenId(x , y);
        require(!_exists(tokenId), "TokenId exists");

        _safeMint(to , tokenId);
    }

    /**
     * @dev Batch mint.
     */    
    function mintMany(address to , int[] calldata x , int[] calldata y) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller unauthorized");
        require(to != address(0) && x.length > 0 && x.length == y.length , "param error");

        uint256 tokenId;
        for(uint i = 0 ; i < x.length ; i++){
            tokenId = _encodeTokenId(x[i] , y[i]);
            require(!_exists(tokenId), "TokenId exists");       
            _safeMint(to , tokenId);
        }
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     */
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to , tokenId);
        totalSupply++;
    }
    
    /**
     * @dev The coordinates are converted to tokenId.
     */    
    function encodeTokenId(int x, int y) external pure returns (uint) {
        return _encodeTokenId(x, y);
    }

    function _encodeTokenId(int x, int y) internal pure returns (uint) {
        return x._encodeTokenId(y);
    }

    /**
     * @dev TokenId is converted to coordinates.
     */    
    function decodeTokenId(uint value) external pure returns (int, int) {
        return _decodeTokenId(value);
    }

    function _decodeTokenId(uint value) internal pure returns (int x, int y) {
        (x , y) = value._decodeTokenId();
    }
    
    /**
     * @dev Set the operator of the owner.
     */    
    function setUpdateManager(address _owner, address _operator, bool _approved) external {
        require(_operator != msg.sender, "operator different owner");
        require(_owner == msg.sender || isApprovedForAll(_owner , msg.sender) , "Unauthorized user");
        updateManager[_owner][_operator] = _approved;
        
        emit UpdateManager(_owner, _operator, msg.sender, _approved);
    }

    /**
     * @dev Set the operator of the tokenId.
     */    
    function setUpdateOperator(uint256 _tokenId , address _operator) public {
        address _owner = ownerOf(_tokenId);
        require(_isApprovedOrOwner(msg.sender , _tokenId) ||  updateManager[_owner][msg.sender] , "Unauthorized user");

        updateOperator[_tokenId] = _operator;

        emit UpdateOperator(_tokenId , _operator);
    }

    /**
     * @dev Batch set the operator of the tokenIds.
     */    
    function setManyUpdateOperator(uint256[] calldata _tokenIds, address _operator) external {
        for (uint i = 0; i < _tokenIds.length; i++) {
            setUpdateOperator(_tokenIds[i], _operator);
        }
    }

    /**
     * @dev Operator whether to have administrator rights for tokenId.
     */    
    function isUpdateAuthorized(address operator, uint256 tokenId) external view returns (bool) {
        return _isUpdateAuthorized(operator, tokenId);
    }

    function _isUpdateAuthorized(address operator, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return owner == operator || updateManager[owner][operator] || updateOperator[tokenId] == operator;
    }

    /**
     * @dev Update land data.
     */    
    function updateLandData(int x , int y , string calldata data) external {
        _updateLandData(x, y, data);
    }

    /**
     * @dev Batch update land data.
     */    
    function updateManyLandData(int[] calldata x, int[] calldata y, string calldata data) external {
        require(x.length > 0 && x.length == y.length, "x , y error");
        for (uint i = 0; i < x.length; i++) {
            _updateLandData(x[i], y[i], data);
        }
    }

    function _updateLandData(int x , int y , string calldata data) internal {
        uint256 _tokenId = _encodeTokenId(x, y);
        require(_isUpdateAuthorized(msg.sender , _tokenId) , "Caller unauthorized");
        _assetData[_tokenId] = data;

        emit UpdateLandData(_tokenId , msg.sender , data);
    }

    /**
     * @dev Returns whether coordinates have been mint.
     */    
    function exists(int x, int y) external view returns (bool) {
        return _exists(_encodeTokenId(x , y));
    }

    /**
     * @dev Returns Owner of coordinates.
     */
    function ownerOfLand(int x, int y) public view returns (address) {
        return ownerOf(_encodeTokenId(x, y));
    }
    
    /**
     * @dev Returns coordinate data.
     */    
    function landData(int x , int y) external view returns(string memory) {
        return _tokenData(_encodeTokenId(x , y));            
    }
  
    /**
     * @dev Returns token ID data.
     */    
    function tokenData(uint256 _tokenId) external view returns(string memory) {
        return _tokenData(_tokenId);
    }

    function _tokenData(uint256 _tokenId) internal view returns(string memory) {
        return _assetData[_tokenId];
    }    

    /**
     * @dev Returns all of owner's lands
     */  
    function landOf(address owner , uint256 pageNum , uint256 showNum) external view returns(uint256[] memory) {
        uint256[] memory lands = new uint256[](showNum);
        uint256 start = pageNum * showNum;
        uint256 end = start + showNum - 1;
        uint256 total = _ownedTokens[owner].length;

        for(uint256 i ; start <= end && start < total ; start++) {
            lands[i++] = _ownedTokens[owner][start];
        }

        return lands;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Set the base uri.
     */    
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */    
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "URI set of nonexistent token");
        return baseURI.getTokenURL(_tokenId);
    }
    
    /**
     * @dev Set the estate contract.
     */
    function setEstateContract(address _estate) external onlyOwner {
        Estate = IEstate(_estate);
        emit SetEstateContract(_estate);
    }

    /**
     * @dev Create estate ID.
     */
    function createEstate(int[] calldata x, int[] calldata y, address to , string calldata metadata) external returns(uint256) {
        return _createEstate(x, y, to , metadata);
    }
        
    function _createEstate(int[] calldata x, int[] calldata y, address to, string memory metadata) internal returns(uint256) {
        address estateAddress = address(Estate);
        require(x.length > 0 && x.length == y.length && estateAddress != address(0), "x , y error or estate not set");

        uint256 estateTokenId = Estate.mint(to, metadata);
        bytes memory estateTokenIdBytes = toBytes(estateTokenId);
        
        for (uint i = 0; i < x.length; i++) {
            uint256 tokenId = _encodeTokenId(x[i], y[i]);
            safeTransferFrom(ownerOf(tokenId), estateAddress , tokenId , estateTokenIdBytes);
        }

        return estateTokenId;
    }

    /**
     * @dev Converts a `uint256` to bytes.
     */    
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly { mstore(add(b, 32), x) }
    }

    /**
     * @dev Transfer Land to estateId
     */    
    function transferLandToEstate(int x, int y, uint256 estateId) external {
        require(Estate.ownerOf(estateId) == msg.sender, "You must own the Estate you want to transfer to");

        uint256 tokenId = _encodeTokenId(x, y);
        safeTransferFrom(ownerOf(tokenId), address(Estate) , tokenId , toBytes(estateId));     
    }

    /**
     * @dev Batch transfer Land to estateId
     */    
    function transferManyLandToEstate(int[] calldata x, int[] calldata y, uint256 estateId) external {
        require(x.length > 0 && x.length == y.length && Estate.ownerOf(estateId) == msg.sender, "param error");
 
        uint256 tokenId;
        address estateAddress = address(Estate);
        bytes memory estateIdBytes = toBytes(estateId);
        for (uint i = 0; i < x.length; i++) {
            tokenId = _encodeTokenId(x[i], y[i]);
            safeTransferFrom(ownerOf(tokenId) , estateAddress , tokenId , estateIdBytes);
        }
    }

    /**
     * @dev 'to' can not be estate contract of transfer.
     */    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(to != address(Estate) , "Estate unsafe transfers are not allowed");
        super.transferFrom(from , to , tokenId);
    }

    /**
     * @dev Transfer by coordinate.
     */    
    function transferLand(int x, int y, address to) external {
        uint256 tokenId = _encodeTokenId(x, y);
        transferFrom(ownerOf(tokenId) , to , tokenId);
    }

    /**
     * @dev Batch transfer by coordinate.
     */    
    function transferManyLand(int[] calldata x, int[] calldata y, address to) external {
        require(x.length > 0 && x.length == y.length, "x , y error");

        uint256 tokenId;
        for (uint i = 0; i < x.length; i++) {
            tokenId = _encodeTokenId(x[i], y[i]);
            transferFrom(ownerOf(tokenId) , to , tokenId);    
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 _tokenId, uint256 batchSize) internal override virtual {
        super._afterTokenTransfer(from , to , _tokenId, batchSize);

        // Delete operator of tokenId.
        delete updateOperator[_tokenId];

        // Remove the tokenId from the 'from', then add the tokenId from the 'to'.
        if(from != address(0)) {
            _removeTokenFromOwner(from , _tokenId);
        }

        _addTokenToOwner(to , _tokenId);
    }

    function _removeTokenFromOwner(address from, uint256 tokenId) private {
        uint256[] storage _array = _ownedTokens[from];

        uint256 lastTokenIndex = _array.length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _array[lastTokenIndex];
            _array[tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        _array.pop();
        delete _ownedTokensIndex[tokenId];
    }
    
    function _addTokenToOwner(address to, uint256 tokenId) private {
        uint256 length = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }


}
