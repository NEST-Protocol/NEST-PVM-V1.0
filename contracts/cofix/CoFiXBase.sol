// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/ICoFiXGovernance.sol";

// Router contract to interact with each CoFiXPair, no owner or governance
/// @dev Base contract of CoFiX
contract CoFiXBase {

    /// @dev ICoFiXGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance ICoFiXGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "CoFiX:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || ICoFiXGovernance(governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(ICoFiXGovernance(_governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "CoFiX:!contract");
        _;
    }
}
