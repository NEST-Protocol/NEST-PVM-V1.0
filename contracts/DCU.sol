// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./HedgeBase.sol";

/// @dev DCU token
contract DCU is HedgeBase, ERC20("Decentralized Currency Unit", "DCU") {

    /// @dev Mining permission flag change event
    /// @param account Target address
    /// @param oldFlag Old flag
    /// @param newFlag New flag
    event MinterChanged(address account, uint oldFlag, uint newFlag);

    // Flags for account
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "DCU:not minter");
        _;
    }

    /// @dev Set mining permission flag
    /// @param account Target address
    /// @param flag Mining permission flag
    function setMinter(address account, uint flag) external onlyGovernance {

        emit MinterChanged(account, _minters[account], flag);
        _minters[account] = flag;
    }

    /// @dev Check mining permission flag
    /// @param account Target address
    /// @return flag Mining permission flag
    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev Mint DCU
    /// @param to Target address
    /// @param value Mint amount
    function mint(address to, uint value) external onlyMinter {
        _mint(to, value);
    }

    /// @dev Burn DCU
    /// @param from Target address
    /// @param value Burn amount
    function burnFrom(address from, uint value) external onlyMinter {
        _burn(from, value);
    }
}