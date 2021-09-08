// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./interfaces/IFortVaultForStaking.sol";

import "./FortFrequentlyUsed.sol";
import "./FortDCU.sol";

import "hardhat/console.sol";

/// @dev Stake xtoken, earn fort
contract FortVaultForStaking is FortFrequentlyUsed, IFortVaultForStaking {

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint balance;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Mining amount weight
        uint weight;
        // 结束区块号
        uint endblock;
        // Total staked amount
        uint totalStaked;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    // // fort mining speed weight base
    // uint constant FORT_WEIGHT_BASE = 1e9;

    // fort mining unit
    uint _fortUnit;
    uint _startblock;

    // staking通道信息xtoken|cycle=>StakeChannel
    mapping(uint=>StakeChannel) _channels;
    
    /// @dev Create FortVaultForStaking
    constructor () {
    }

    /// @dev Modify configuration
    /// @param fortUnit fort mining unit
    function setConfig(uint fortUnit) external onlyGovernance {
        _fortUnit = fortUnit;
    }

    /// @dev Get configuration
    /// @return fortUnit fort mining unit
    function getConfig() external view returns (uint fortUnit) {
        return _fortUnit;
    }

    // TODO: 周期改为固定区块
    /// @dev Initialize ore drawing weight
    /// @param startblock 锁仓起始区块
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        uint startblock,
        address[] calldata xtokens, 
        uint96[] calldata cycles, 
        uint[] calldata weights
    ) external override onlyGovernance {

        uint cnt = xtokens.length;
        require(cnt == weights.length && cnt == cycles.length, "FVFS:mismatch len");

        for (uint i = 0; i < cnt; ++i) {
            address xtoken = xtokens[i];
            //require(xtoken != address(0), "FVFS:invalid xtoken");
            uint key = _getKey(xtoken, cycles[i]);
            StakeChannel storage channel = _channels[key];
            channel.endblock = startblock + uint(cycles[i]);
            channel.weight = weights[i];
            channel.totalStaked = 0;
        }

        _startblock = startblock;
    }

    /// @dev Get stake channel information
    /// @param xtoken xtoken address
    /// @param cycle cycle
    /// @return totalStaked Total lock volume of target xtoken
    /// @return totalRewards 通道总出矿量
    /// @return startblock 锁仓起始区块
    /// @return endblock 锁仓结束区块（达到结束区块后可以领取分红）
    function getChannelInfo(
        address xtoken, 
        uint96 cycle
    ) external view override returns (
        uint totalStaked, 
        uint totalRewards,
        uint startblock,
        uint endblock
    ) {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        return (
            channel.totalStaked, 
            channel.weight * _fortUnit, 
            _startblock, 
            channel.endblock
        );
    }

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view override returns (uint) {
        return uint(_channels[_getKey(xtoken, cycle)].accounts[addr].balance);
    }

    /// @dev Get the number of fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return The number of fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view override returns (uint) {

        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        if (block.number < channel.endblock) {
            return 0;
        }
        return channel.weight * _fortUnit * channel.accounts[addr].balance / channel.totalStaked;
    }

    /// @dev Stake xtoken to earn fort
    /// @param xtoken xtoken address
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external override {

        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // TODO: 结束时间不一样?
        require(block.number >= _startblock && block.number < channel.endblock, "FVFS:!block");
        // Settle reward for account
        Account memory account = channel.accounts[msg.sender];

        // Transfer xtoken from msg.sender to this
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), amount);
        // Update totalStaked
        channel.totalStaked += amount;

        // Update stake balance of account
        account.balance += amount;
        channel.accounts[msg.sender] = account;
    }

    /// @dev Withdraw xtoken, and claim earned fort
    /// @param xtoken xtoken address
    function withdraw(address xtoken, uint96 cycle) external override {

        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);
        uint amount = account.balance;

        // Update totalStaked
        //channel.totalStaked -= amount;
        // Update stake balance of account
        account.balance = 0; //uint160(uint(account.balance) - amount);
        channel.accounts[msg.sender] = account;

        // Transfer xtoken to msg.sender
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    // /// @dev Claim fort
    // /// @param xtoken xtoken address
    // function getReward(address xtoken, uint96 cycle) external override {
    //     StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
    //     channel.accounts[msg.sender] = _getReward(channel, msg.sender);
    // }

    // Calculate reward, and settle the target account
    function _getReward(
        StakeChannel storage channel, 
        address to
    ) private returns (Account memory account) {

        // Load account
        account = channel.accounts[to];

        if (block.number >= channel.endblock) {
            uint reward = channel.weight * _fortUnit * account.balance / channel.totalStaked;
            // Transfer fort to account
            if (reward > 0) {
                FortDCU(FORT_TOKEN_ADDRESS).mint(to, reward);
            }
        }
    }

    function _getKey(address xtoken, uint96 cycle) public pure returns (uint){
        return (uint(uint160(xtoken)) << 96) | uint(cycle);
    }
}
