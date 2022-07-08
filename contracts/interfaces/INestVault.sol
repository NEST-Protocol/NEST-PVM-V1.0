// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Nest Vault
interface INestVault {

    function approve(address target, uint limit) external;

    function transferTo(address to, uint amount) external;
}