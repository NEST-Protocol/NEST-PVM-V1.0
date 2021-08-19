// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/INestPriceFacade.sol";

import "./FortBase.sol";

/// @dev Fort代币
contract FortToken is FortBase, ERC20("Fort", "Fort") {

    // 保存挖矿权限地址
    mapping(address=>uint) _minters;

    constructor() {
    }

    modifier onlyMinter {
        require(_minters[msg.sender] == 1, "FortToken: not minter");
        _;
    }

    /// @dev 设置挖矿权限
    /// @param account 目标账号
    /// @param flag 挖矿权限标记，只有1表示可以挖矿
    function setMinter(address account, uint flag) external onlyGovernance {
        _minters[account] = flag;
    }

    function checkMinter(address account) external view returns (uint) {
        return _minters[account];
    }

    /// @dev 挖矿
    /// @param to 接受地址
    /// @param amount 挖矿数量
    function mint(address to, uint amount) external onlyMinter {
        //require(msg.sender == _owner, "FortToken: not owner");
        _mint(to, amount);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param amount 销毁数量
    function burn(address from, uint amount) external onlyMinter {
        //require(msg.sender == _owner, "FortToken: not owner");
        _burn(from, amount);
    }
}