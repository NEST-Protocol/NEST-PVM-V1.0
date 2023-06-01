// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./CommonBase.sol";

/// @dev Proxy for contract
contract CommonProxy is CommonBase {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // /**
    //  * @dev Governance slot with the address of the current governance.
    //  * This is the keccak-256 hash of "eip1967.proxy.governance" subtracted by 1, and is
    //  * validated in the constructor.
    //  */
    // bytes32 internal constant _GOVERNANCE_SLOT = 0xbed87926877ae85dc73dd485e04c4e6294f0fff2ab53c81d2cb03ebca9719a4a;

    constructor(address implementation) {
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate() internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), sload(_IMPLEMENTATION_SLOT), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // /**
    //  * @dev Returns the current implementation address.
    //  */
    // function getImplementation() external view returns (address v) {
    //     assembly {
    //         v := sload(_IMPLEMENTATION_SLOT)
    //     }
    // }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function setImplementation(address newImplementation) external onlyGovernance {
        //require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        //StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _delegate();
    }
}
