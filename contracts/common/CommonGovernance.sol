// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/ICommonGovernance.sol";

import "./CommonBase.sol";

contract CommonGovernance is CommonBase, ICommonGovernance {

    constructor() {
        assembly {
            mstore(0, caller())
            sstore(keccak256(0, 0x20), 1)
        }
    }

    function setAdministrator(address target, uint flag) external override onlyGovernance {
        assembly {
            mstore(0, caller())
            sstore(keccak256(0, 0x20), flag)
        }
    }

    function checkAdministrator(address target) external view override returns (uint flag) {
        assembly {
            mstore(0, caller())
            flag := sload(keccak256(0, 0x20))
        }
    }

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external override onlyGovernance {
        assembly {
            sstore(keccak256(add(key, 0x20), mload(key)), addr)
        }
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return addr Destination address. 0 means empty
    function checkAddress(string memory key) external view override returns (address addr) {
        assembly {
            addr := sload(keccak256(add(key, 0x20), mload(key)))
        }
    }

    /// @dev Execute transaction from NestGovernance
    /// @param target Target address
    /// @param data Calldata
    /// @return success Return data in bytes
    function execute(address target, bytes calldata data) external payable override returns (bool success) {
        assembly {
            mstore(0, caller())
            if iszero(sload(keccak256(0, 0x20))) {
                mstore(0, "COM:!gov")
                revert(0, 0x20) 
            }
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