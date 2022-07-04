// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/IFortVault.sol";

import "./FortBase.sol";

/// @dev Fort Vault
contract FortVault is FortBase, IFortVault {

    address NEST_TOKEN_ADDRESS;

    // TODO:
    function setAddress(address nest) external onlyGovernance {
        NEST_TOKEN_ADDRESS = nest;
    }

    mapping(address=>uint) _allowances;

    function approve(address target, uint limit) external override onlyGovernance {
        _allowances[target] = limit;
    }

    function transferTo(address to, uint amount) external override {
        require(_allowances[msg.sender] >= amount, "FV:exceeded allowance");
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amount);
    }
}
