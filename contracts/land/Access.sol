// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Access operations.
 */
contract Access {

    // Mapping from role to address.
    mapping(bytes32 => mapping(address => bool)) private _roles;

    /**
     * @dev Emitted when set the permissions.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    
    /**
     * @dev Emitted when Revoke permissions.
     */    
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Set the permissions.
     */    
    function _grantRole(bytes32 role , address account) internal virtual{
        if(!hasRole(role , account)){
            _roles[role][account] = true;
            emit RoleGranted(role , account , msg.sender);
        }
    }

    /**
     * @dev Revoke permissions.
     */    
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role , account , msg.sender);
        }
    }


    /**
     * @dev Check the permissions.
     */    
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role][account];
    }



}