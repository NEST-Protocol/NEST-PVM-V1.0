// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./interfaces/IFortVaultForStaking.sol";

import "./FortFrequentlyUsed.sol";
import "./FortDCU.sol";

/// @dev Stake xtoken, earn fort
contract FortVaultForStaking is FortFrequentlyUsed, IFortVaultForStaking {

    /* *******************************************************************
        定义三个操作：锁仓，领取fort，取回

        ----------------[1]-----[2]---------------[3]------------------->

        a.  一共三个时间节点：1， 2， 3。
            对于所有质押通道：1和2时间节点都是一样的，不同的质押通道3是不一样的。
            质押周期表示2~3之间的时间
            时间折算成区块估算

        b. 1节点之前啥都不能操作
        c. 1节点到2节点期间可以质押
        d. 2节点以后可以执行领取操作
        e. 3节点以后可以执行取回操作
    ******************************************************************* */

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 rewardCursor;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Total staked amount
        uint192 totalStaked;

        // 解锁区块号
        uint64 unlockBlock;

        // Mining amount weight
        uint160 weight;

        // The dividend mark that the settled company token can receive
        uint96 rewardPerToken;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    uint constant UI128 = 0x100000000000000000000000000000000;

    // Fort出矿单位
    uint128 _fortUnit;
    // staking开始区块号
    uint64 _startBlock;
    // staking截止区块号
    uint64 _stopBlock;

    // staking通道信息xtoken=>StakeChannel
    mapping(uint=>StakeChannel) _channels;
    
    /// @dev Create FortVaultForStaking
    constructor () {
    }

    /// @dev Modify configuration
    /// @param fortUnit Fort出矿单位
    /// @param startBlock staking开始区块号
    /// @param stopBlock staking截止区块号
    function setConfig(uint128 fortUnit, uint64 startBlock, uint64 stopBlock) external onlyGovernance {
        _fortUnit = fortUnit;
        _startBlock = startBlock;
        _stopBlock = stopBlock;
    }

    /// @dev Get configuration
    /// @return fortUnit Fort出矿单位
    /// @return startBlock staking开始区块号
    /// @return stopBlock staking截止区块号
    function getConfig() external view returns (uint fortUnit, uint startBlock, uint stopBlock) {
        return (uint(_fortUnit), uint(_startBlock), uint(_stopBlock));
    }

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        address[] calldata xtokens, 
        uint64[] calldata cycles, 
        uint160[] calldata weights
    ) external override onlyGovernance {
        uint64 stopBlock = _stopBlock;
        uint cnt = xtokens.length;
        require(cnt == weights.length && cnt == cycles.length, "FVFS:mismatch len");

        for (uint i = 0; i < cnt; ++i) {
            address xtoken = xtokens[i];
            //require(xtoken != address(0), "FVFS:invalid xtoken");
            StakeChannel storage channel = _channels[_getKey(xtoken, cycles[i])];
            _updateReward(channel);

            channel.weight = weights[i];
            channel.unlockBlock = stopBlock + cycles[i];
        }
    }

    /// @dev Get stake channel information
    /// @param xtoken xtoken address
    /// @param cycle cycle
    /// @return totalStaked Total lock volume of target xtoken
    /// @return totalRewards 通道总出矿量
    /// @return unlockBlock 解锁区块号
    function getChannelInfo(
        address xtoken, 
        uint64 cycle
    ) external view override returns (
        uint totalStaked, 
        uint totalRewards,
        uint unlockBlock
    ) {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        return (
            uint(channel.totalStaked), 
            uint(channel.weight) * uint(_fortUnit), 
            uint(channel.unlockBlock) 
        );
    }

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address
    /// @param cycle cycle
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint64 cycle, address addr) external view override returns (uint) {
        return uint(_channels[_getKey(xtoken, cycle)].accounts[addr].balance);
    }

    /// @dev Get the number of Fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    /// @param addr Target address
    /// @return The number of Fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint64 cycle, address addr) external view override returns (uint) {
        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);
        
        // Load account
        Account memory account = channel.accounts[addr];
        uint balance = uint(account.balance);
        // Load total amount of staked
        uint totalStaked = uint(channel.totalStaked);

        // Unit token dividend
        uint rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * UI128 / totalStaked;
        }
        
        return (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / UI128;
    }

    /// @dev Stake xtoken to earn Fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    /// @param amount Stake amount
    function stake(address xtoken, uint64 cycle, uint160 amount) external override {

        require(block.number >= uint(_startBlock) && block.number <= uint(_stopBlock), "FVFS:!block");
        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        require(uint(channel.weight) > 0, "FVFS:no reward");
        
        // Transfer xtoken from msg.sender to this
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), uint(amount));
        
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);

        // Update totalStaked
        channel.totalStaked += uint192(amount);

        // Update stake balance of account
        account.balance += amount;
        channel.accounts[msg.sender] = account;
    }

    /// @dev Withdraw xtoken, and claim earned Fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    function withdraw(address xtoken, uint64 cycle) external override {
        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        require(block.number >= uint(channel.unlockBlock), "FVFS:!block");

        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);
        uint amount = uint(account.balance);

        // Update totalStaked
        channel.totalStaked -= uint192(amount);
        // Update stake balance of account
        account.balance = uint160(0);
        channel.accounts[msg.sender] = account;

        // Transfer xtoken to msg.sender
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    /// @dev Claim Fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    function getReward(address xtoken, uint64 cycle) external override {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        channel.accounts[msg.sender] = _getReward(channel, msg.sender);
    }

    // Calculate reward, and settle the target account
    function _getReward(
        StakeChannel storage channel, 
        address to
    ) private returns (Account memory account) {
        // Load account
        account = channel.accounts[to];
        // Update the global dividend information and get the new unit token dividend amount
        uint rewardPerToken = _updateReward(channel);
        
        // Calculate reward for account
        uint balance = uint(account.balance);
        uint reward = (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / UI128;
        
        // Update sign of account
        account.rewardCursor = _encodeFloat(rewardPerToken);
        //channel.accounts[to] = account;

        // Transfer Fort to account
        if (reward > 0) {
            FortDCU(FORT_TOKEN_ADDRESS).mint(to, reward);
        }
    }

    // Update the global dividend information and return the new unit token dividend amount
    function _updateReward(StakeChannel storage channel) private returns (uint rewardPerToken) {
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = uint(channel.totalStaked);
        
        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * UI128 / totalStaked;
        }

        // Update the dividend value of unit share
        channel.rewardPerToken = _encodeFloat(rewardPerToken);
        if (newReward > 0) {
            channel.weight = uint160(0);
        }
    }

    // Calculate new reward
    function _calcReward(StakeChannel storage channel) private view returns (uint newReward) {

        if (block.number > uint(_stopBlock)) {
            newReward = uint(channel.weight) * uint(_fortUnit);
        } else {
            newReward = 0;
        }
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint96) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint96((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint96 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    function _getKey(address xtoken, uint64 cycle) private pure returns (uint){
        return (uint(uint160(xtoken)) << 96) | uint(cycle);
    }
}
