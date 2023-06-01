// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/ICommonGovernance.sol";

import "./CommonBase.sol";

contract CommonGovernance is CommonBase, ICommonGovernance {

    mapping(address=>uint) _administrators;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    constructor() {
        _administrators[msg.sender] = 1;
    }

    function setAdministrator(address target, uint flag) external override onlyGovernance {
        _administrators[target] = flag;
    }

    function checkAdministrator(address target) external view override returns (uint) {
        return _administrators[target];
    }

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external override onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view override returns (address) {
        return _registeredAddress[key];
    }

    /// @dev Execute transaction from NestGovernance
    /// @param target Target address
    /// @param data Calldata
    /// @return success Return data in bytes
    function execute(address target, bytes calldata data) external payable override returns (bool success) {
        require(_administrators[msg.sender] > 0, "COM:!gov");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, data.offset, data.length)

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            success := call(gas(), target, callvalue(), 0, data.length, 0, 0)
            // // Copy the returned data.
            // returndatacopy(0, 0, returndatasize())

            switch success
            // delegatecall returns 0 on error.
            case 0 { 
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize()) 
            }
            default {
                mstore(0, success)
                return(0, 0x20) 
            }
            // if iszero(success) { 
            //     mstore(0, "GOV:execute failed!")
            //     revert(0, 0x20) 
            // }
        }
    }
}