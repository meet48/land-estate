// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EstateStorage.sol";

/**
 * @dev Estate.
 */
contract Estate is ERC721 , Ownable , EstateStorage{

    constructor() ERC721("Meet48 ESTATE", "ESTATE") {

    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer ownership.
     */    
    function transferOwnership(address _newOwner) public override onlyOwner{
        require(_newOwner != address(0), "zero address");
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Set the land contract.
     */    
    function setLandContract(address _land) external onlyOwner {
        require(_land != address(0) && _isContract(_land) , "The LAND registry address should be valid");
        Land = ILAND(_land);
        emit SetLandContract(_land);
    }

    /**
     * @dev Msg.sender has to be land contract.
     */    
    modifier onlyLandContract() {
        require(msg.sender == address(Land), "Only the land can make this operation");
        _;
    }

    /**
     * @dev Mint.
     * @param {address} 'to' cannot be the zero address.
     * @param {string calldata} 'metadata' estateData.
     * @return {estateId}.
     */    
    function mint(address to , string calldata metadata) external onlyLandContract returns(uint256){
        require(to != address(0) , "to zero address");

        uint256 estateId = ++totalSupply;
        _safeMint(to , estateId);
        _updateMetadata(estateId, metadata);

        emit CreateEstate(to , estateId , metadata);
        return estateId;
    }

    /**
     * @dev Received ERC721.
     */    
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) public onlyLandContract returns (bytes4) {
        uint256 estateId = uint256(_bytesToBytes32(_data));
        _pushLandId(estateId, _tokenId);
        emit ReceiveLand(_operator , _from , _tokenId , estateId);       
        return type(IERC721Receiver).interfaceId;
    }

    function _bytesToBytes32(bytes calldata b) internal pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i*8);
        }
        return out;
    }

    /**
     * @dev Add landId to estateId.
     */    
    function _pushLandId(uint256 estateId, uint256 landId) internal {
        require(_exists(estateId), "The Estate id should exist");
        require(landIdEstate[landId] == 0, "The LAND is already owned by an Estate");
        require(Land.ownerOf(landId) == address(this), "The EstateRegistry cannot manage the LAND");

        estateLandIds[estateId].push(landId);
        _estateLandIndex[estateId][landId] = estateLandIds[estateId].length;

        landIdEstate[landId] = estateId;

        emit AddLand(estateId , landId);
    }

    /**
     * @dev Remove landId from estateId.
     */    
    function transferLand(uint256 estateId , uint256 landId, address to) external canTransfer(estateId) {
        return _transferLand(estateId , landId , to);
    }

    /**
     * @dev Batch remove landId from estateId.
     */    
    function transferManyLands(uint256 estateId , uint256[] calldata landIds , address to) external canTransfer(estateId) {
        uint length = landIds.length;
        for (uint i = 0; i < length; i++) {
            _transferLand(estateId, landIds[i], to);
        }
    }

    function _transferLand(uint256 estateId , uint256 landId , address to) internal {
        require(to != address(0), "You can not transfer LAND to an empty address");

        uint256[] storage landIds = estateLandIds[estateId];
        mapping(uint256 => uint256) storage landIndex = _estateLandIndex[estateId];

        // Whether landId exists in estateId.
        require(landIdEstate[landId] == estateId && landIndex[landId] != 0, "The LAND is not part of the Estate");

        // The index of an landId in an estateLandIds.
        uint indexInArray = landIndex[landId] - 1;

        // indexInArray and lastIndex exchange values.
        uint lastTokenId = landIds[landIds.length - 1];
        landIds[indexInArray] = lastTokenId;
        landIndex[lastTokenId] = indexInArray + 1;
 
        // Delete.
        landIds.pop();
        delete landIndex[landId];
        delete landIdEstate[landId];
 
        Land.safeTransferFrom(address(this), to , landId);
        emit RemoveLand(estateId, landId, to);
    }

    /**
     * @dev Is can remove landId of estateId.
     */    
    modifier canTransfer(uint256 estateId) {
        require(_isApprovedOrOwner(msg.sender , estateId), "Only owner or operator can transfer");
        _;
    }

    /**
     * @dev Is can set the operator of the estateId.
     */    
    modifier canSetUpdateOperator(uint256 estateId) {
        address owner = ownerOf(estateId);
        require(_isApprovedOrOwner(msg.sender , estateId) || updateManager[owner][msg.sender], "Unauthorized user");
        _;
    }

    /**
     * @dev EstateId update authentication.
     */    
    modifier onlyUpdateAuthorized(uint256 estateId) {
        require(_isUpdateAuthorized(msg.sender, estateId), "Unauthorized user");
        _;
    }


    /**
     * @dev Whether 'operator' can update 'estateId'.
     */    
    function isUpdateAuthorized(address operator, uint256 estateId) external view returns (bool) {
        return _isUpdateAuthorized(operator, estateId);
    }


    function _isUpdateAuthorized(address operator, uint256 estateId) internal view returns (bool) {
        address owner = ownerOf(estateId);
        return _isApprovedOrOwner(operator, estateId) || updateOperator[estateId] == operator || updateManager[owner][operator];
    }

    /**
     * @dev LandId updates authentication.
     */    
    modifier onlyLandUpdateAuthorized(uint256 estateId, uint256 landId) {
        require(_isUpdateAuthorized(msg.sender, estateId) || Land.updateOperator(landId) == msg.sender , "unauthorized user");
        _;
    }

    /**
     * @dev Set the operator of the owner.
     */    
    function setUpdateManager(address _owner, address _operator, bool _approved) external {
        require(_operator != msg.sender, "The operator should be different from owner");
        require(_owner == msg.sender || isApprovedForAll(_owner , msg.sender), "Unauthorized user");
        updateManager[_owner][_operator] = _approved;
        emit UpdateManager(_owner, _operator, msg.sender, _approved);
    }

    /**
     * @dev set the operator of the estateId.
     */    
    function setUpdateOperator(uint256 estateId, address operator) public canSetUpdateOperator(estateId) {
        updateOperator[estateId] = operator;
        emit UpdateOperator(estateId, operator);
    }

    /**
     * @dev Batch set the operator of the estateId.
     */    
    function setManyUpdateOperator(uint256[] calldata _estateIds, address _operator) public {
        for (uint i = 0; i < _estateIds.length; i++) {
            setUpdateOperator(_estateIds[i], _operator);
        }
    }

    /**
     * @dev Update estateId data.
     */    
    function updateMetadata(uint256 estateId, string calldata metadata) external onlyUpdateAuthorized(estateId) {
        _updateMetadata(estateId, metadata);
        emit UpdateData(estateId, ownerOf(estateId), msg.sender, metadata);
    }

    function _updateMetadata(uint256 estateId, string calldata metadata) internal {
        estateData[estateId] = metadata;
    }

    /**
     * @dev Update land data.
     */    
    function updateLandData(uint256 estateId, uint256 landId, string calldata data) public {
        _updateLandData(estateId, landId, data);
    }

    /**
     * @dev Batch update land data.
     */    
    function updateManyLandData(uint256 estateId, uint256[] calldata landIds, string calldata data) public {
        uint length = landIds.length;
        for (uint i = 0; i < length; i++) {
            _updateLandData(estateId, landIds[i], data);
        }
    }

    function _updateLandData(uint256 estateId, uint256 landId, string calldata data) internal onlyLandUpdateAuthorized(estateId, landId) {
        _isLandIdInEstate(landId , estateId);
        int x;
        int y;
        (x, y) = Land.decodeTokenId(landId);
        Land.updateLandData(x, y, data);
    }

    /**
     * @dev Set the operator of the landId.
     */    
    function setLandUpdateOperator(uint256 estateId, uint256 landId, address operator) public canSetUpdateOperator(estateId) {
        _isLandIdInEstate(landId , estateId);
        Land.setUpdateOperator(landId, operator);
    }

    /**
     * @dev Batch set the operator of the landId.
     */    
    function setManyLandUpdateOperator(uint256 _estateId, uint256[] calldata _landIds, address _operator) public canSetUpdateOperator(_estateId) {
        for (uint i = 0; i < _landIds.length; i++) {
            _isLandIdInEstate(_landIds[i] , _estateId);
        }
        Land.setManyUpdateOperator(_landIds, _operator);
    }

    function _isLandIdInEstate(uint256 landId , uint256 estateId) private view {
        require(landIdEstate[landId] == estateId, "The LAND is not part of the Estate");
    }

    /**
     * @dev Returns the number of landId's in estateId.
     */    
    function getSize(uint256 estateId) external view returns (uint256) {
        return estateLandIds[estateId].length;
    }

    /**
     * @dev Returns all landId's in estateId.
     */    
    function getLandIds(uint256 estateId) external view returns(uint256[] memory) {
        return estateLandIds[estateId];
    }

    /**
     * @dev Returns estateId data.
     */    
    function getMetadata(uint256 estateId) external view returns (string memory) {
        return estateData[estateId];
    }

    /**
     * @dev Returns land total.
     */    
    function getLandTotal(address _owner) external view returns (uint256) {
        uint256 total;
        uint256 length = _ownedTokens[_owner].length;
        for (uint256 i; i < length; i++) {
            uint256 estateId = _ownedTokens[_owner][i];
            total += estateLandIds[estateId].length;
        }
        return total;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        require(index < balanceOf(owner), "index out of bounds");
        return _ownedTokens[owner][index];
    }

    function estateOf(address owner) external view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function _afterTokenTransfer(address from, address to, uint256 _tokenId, uint256 batchSize) internal override {
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

    function _isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }



}
