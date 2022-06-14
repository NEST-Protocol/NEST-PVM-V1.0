// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IFortGovernance.sol";

/// @dev Base contract of Fort
contract FortBase {

    /// @dev Governance address changed event
    /// @param oldGovernance Old governance address
    /// @param newGovernance New governance address
    event GovernanceChanged(address oldGovernance, address newGovernance);

    /// @dev IFortGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Fort:!initialize");
        emit GovernanceChanged(address(0), governance);
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public virtual {
        address governance = _governance;
        require(governance == msg.sender || IFortGovernance(governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        emit GovernanceChanged(governance, newGovernance);
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IFortGovernance(_governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _;
    }
}
