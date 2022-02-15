// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IHedgeVaultForStaking.sol";

import "./custom/HedgeFrequentlyUsed.sol";

import "./DCU.sol";

/// @dev Stake xtoken, earn dcu
contract HedgeVaultForStaking is HedgeFrequentlyUsed, IHedgeVaultForStaking {

    /* *******************************************************************
        There are three options: Stake, Get Reward, Withdraw

        ----------------[1]-----[2]---------------[3]------------------->

        a.  3 time points: 1, 2, 3.
            For every stake channel, point 1 and 2 are the same, but point 3 
            are not the same for each stake channel.
            2 to 3 is stake period. Time converted into block by estimation

        b. Before point 1, you can't do noting.
        c. Between point 1 and point2, you can Stake.
        d. After point 2, you can Get Reward.
        e. After point 3, you can Withdraw.
    ******************************************************************* */

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 rewardCursor;
        //? Claimed reward, set manual
        uint claimed;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Total staked amount
        uint192 totalStaked;

        // Unlock block number
        uint64 unlockBlock;

        // Mining amount weight
        uint160 weight;

        //? The dividend mark that the settled company token can receive
        uint96 rewardPerToken0;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;

        //? New rewardPerToken
        uint96 rewardPerToken;
    }
    
    uint constant UI128 = 0x100000000000000000000000000000000;

    // dcu reward unit
    uint128 _dcuUnit;
    // staking start block number
    uint64 _startBlock;
    // staking stop block number
    uint64 _stopBlock;

    // Stake channels. xtoken=>StakeChannel
    mapping(uint=>StakeChannel) _channels;
    
    /// @dev Create HedgeVaultForStaking
    constructor () {
    }

    //? Set claimed reward
    function setClaimed(address xtoken, uint64 cycle, address target, uint claimed) external onlyGovernance {
        _channels[_getKey(xtoken, cycle)].accounts[target].claimed = claimed;
    }

    /// @dev Modify configuration
    /// @param dcuUnit dcu reward unit
    /// @param startBlock staking start block number
    /// @param stopBlock staking stop block number
    function setConfig(uint128 dcuUnit, uint64 startBlock, uint64 stopBlock) external onlyGovernance {
        _dcuUnit = dcuUnit;
        _startBlock = startBlock;
        _stopBlock = stopBlock;
    }

    /// @dev Get configuration
    /// @return dcuUnit dcu reward unit
    /// @return startBlock staking start block number
    /// @return stopBlock staking stop block number
    function getConfig() external view returns (uint dcuUnit, uint startBlock, uint stopBlock) {
        return (uint(_dcuUnit), uint(_startBlock), uint(_stopBlock));
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
    /// @return totalRewards Total rewards for channel
    /// @return unlockBlock Unlock block number
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
            uint(channel.weight) * uint(_dcuUnit), 
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

    /// @dev Get the number of DCU to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    /// @param addr Target address
    /// @return The number of DCU to be collected by the target address on the designated transaction lock
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
        
        //? earned
        uint e = (rewardPerToken - _getRewardCursor(account, channel)) * balance / UI128;
        // Deduct claimed amount
        uint claimed = account.claimed;
        if (e > claimed) {
            return e - claimed;
        }
        return 0;
    }

    /// @dev Stake xtoken to earn DCU
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

    /// @dev Withdraw xtoken, and claim earned DCU
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

    /// @dev Claim DCU
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    function getReward(address xtoken, uint64 cycle) external override {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        channel.accounts[msg.sender] = _getReward(channel, msg.sender);
    }

    //? Get reward cursor
    function _getRewardCursor(Account memory account, StakeChannel storage channel) private view returns (uint) {
        uint96 rewardCursor = account.rewardCursor;
        uint96 rewardPerToken = channel.rewardPerToken0;
        if (rewardCursor == rewardPerToken) {
            return 0;
        }
        return _decodeFloat(rewardCursor);
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
        //? new reward
        uint reward = (rewardPerToken - _getRewardCursor(account, channel)) * balance / UI128;
        
        // Update sign of account
        account.rewardCursor = _encodeFloat(rewardPerToken);
        //channel.accounts[to] = account;

        // Transfer DCU to account
        // Deduct claimed amount
        uint claimed = account.claimed;
        if (reward > claimed) {
            reward -= claimed;
            if (reward > 0) {
                DCU(DCU_TOKEN_ADDRESS).mint(to, reward);
            }
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
            newReward = uint(channel.weight) * uint(_dcuUnit);
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
