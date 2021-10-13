// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./HedgeBase.sol";

/// @dev DCU代币
contract DCU is HedgeBase, ERC20("Decentralized Currency Unit", "DCU") {

    // 保存挖矿权限地址
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "DCU:not minter");
        _;
    }

    /// @dev 设置挖矿权限
    /// @param account 目标账号
    /// @param flag 挖矿权限标记，只有1表示可以挖矿
    function setMinter(address account, uint flag) external onlyGovernance {
        _minters[account] = flag;
    }

    /// @dev 检查挖矿权限
    /// @param account 目标账号
    /// @return flag 挖矿权限标记，只有1表示可以挖矿
    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev 铸币
    /// @param to 接受地址
    /// @param value 铸币数量
    function mint(address to, uint value) external onlyMinter {
        _mint(to, value);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    function burn(address from, uint value) external onlyMinter {
        _burn(from, value);
    }
}