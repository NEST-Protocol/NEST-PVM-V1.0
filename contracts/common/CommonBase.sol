// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

contract CommonBase {

    /**
     * @dev Governance slot with the address of the current governance.
     * This is the keccak-256 hash of "eip1967.proxy.governance" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _GOVERNANCE_SLOT = 0xbed87926877ae85dc73dd485e04c4e6294f0fff2ab53c81d2cb03ebca9719a4a;

    constructor() {
        assembly {
            sstore(_GOVERNANCE_SLOT, caller())
        }
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    function setGovernance(address newGovernance) public onlyGovernance {
        assembly {
            sstore(_GOVERNANCE_SLOT, newGovernance)
        }
    }

    function _onlyGovernance() internal view {
        // TODO: Compare gas cost between two methods 
        // address governance;
        // assembly {
        //     governance := sload(_GOVERNANCE_SLOT)
        // }
        // require(msg.sender == governance, "COM:!gov");

        assembly {
            if iszero(eq(caller(), sload(_GOVERNANCE_SLOT))) {
                mstore(0, "!GOV")
                revert(0, 0x20) 
            }
        }
    }

    // function update(address governance) public virtual onlyGovernance {
    // }
}