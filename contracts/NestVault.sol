// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./interfaces/INestVault.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Nest Vault
contract NestVault is NestFrequentlyUsed, INestVault {

    mapping(address=>uint) _allowances;

    function approve(address target, uint limit) external override onlyGovernance {
        _allowances[target] = limit;
    }

    function transferTo(address to, uint amount) external override {
        require(_allowances[msg.sender] >= amount, "NV:exceeded allowance");
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, amount);
    }
}
