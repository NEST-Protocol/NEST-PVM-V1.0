// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortVaultForStaking.sol";

import "./FortBase.sol";
import "./FortToken.sol";

/// @dev Stake xtoken or CNode, earn CoFi
contract FortVaultForStaking is FortBase, IFortVaultForStaking {

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 rewardCursor;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Mining amount weight
        uint weight;
        // 结束区块号
        uint endblock;
        // Total staked amount
        uint totalStaked;

        // xtoken global sign
        // Total ore drawing mark of settled transaction
        uint128 tradeReward;
        // Total settled ore output mark
        //uint128 totalReward;
        // The dividend mark that the settled company token can receive
        uint96 rewardPerToken;
        // Settlement block mark
        uint32 blockCursor;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    // // CoFi mining speed weight base
    // uint constant FORT_WEIGHT_BASE = 1e9;

    // CoFi mining unit
    uint _fortUnit;

    // staking通道信息xtoken|cycle=>StakeChannel
    mapping(uint=>StakeChannel) _channels;
    
    /// @dev Create FortVaultForStaking
    constructor () {
    }

    // /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    // ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    // /// @param newGovernance IFortGovernance implementation contract address
    // function update(address newGovernance) public override {
    //     super.update(newGovernance);
    //     _cofixRouter = IFortGovernance(newGovernance).getFortRouterAddress();
    // }

    /// @dev Modify configuration
    /// @param fortUnit CoFi mining unit
    function setConfig(uint fortUnit) external onlyGovernance {
        _fortUnit = fortUnit;
    }

    /// @dev Get configuration
    /// @return fortUnit CoFi mining unit
    function getConfig() external view returns (uint fortUnit) {
        return _fortUnit;
    }

    function _getKey(address xtoken, uint96 cycle) private pure returns (uint){
        return (uint160(xtoken) << 96) | uint(cycle);
    }

    // TODO: 周期改为固定区块
    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        address[] calldata xtokens, 
        uint96[] calldata cycles, 
        uint[] calldata weights
    ) external override onlyGovernance {
        uint cnt = xtokens.length;
        require(cnt == weights.length, "FortVaultForStaking: mismatch len");
        for (uint i = 0; i < cnt; ++i) {
            address xtoken = xtokens[i];
            require(xtoken != address(0), "FortVaultForStaking: invalid xtoken");
            uint key = _getKey(xtoken, cycles[i]);
            StakeChannel storage channel = _channels[key];
            _updateReward(channel);
            channel.weight = weights[i];
            channel.endblock = block.number + cycles[i];
        }
    }

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return cofiPerBlock Mining speed, cofi per block
    function getChannelInfo(
        address xtoken, 
        uint96 cycle
    ) external view override returns (
        uint totalStaked, 
        uint cofiPerBlock
    ) {
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        return (channel.totalStaked, uint(channel.weight) * _fortUnit);
    }

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view override returns (uint) {
        return uint(_channels[_getKey(xtoken, cycle)].accounts[addr].balance);
    }

    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view override returns (uint) {
        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);
        
        // Load account
        Account memory account = channel.accounts[addr];
        uint balance = uint(account.balance);
        // Load total amount of staked
        uint totalStaked = channel.totalStaked;

        // Unit token dividend
        uint rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
        
        return (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
    }

    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external override {
        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);

        // Transfer xtoken from msg.sender to this
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), amount);
        // Update totalStaked
        channel.totalStaked += amount;

        // Update stake balance of account
        account.balance = uint160(uint(account.balance) + amount);
        channel.accounts[msg.sender] = account;
    }

    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint96 cycle, uint amount) external override {
        // Load stake channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Settle reward for account
        Account memory account = _getReward(channel, msg.sender);

        // Update totalStaked
        channel.totalStaked -= amount;
        // Update stake balance of account
        account.balance = uint160(uint(account.balance) - amount);
        channel.accounts[msg.sender] = account;

        // Transfer xtoken to msg.sender
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken, uint96 cycle) external override {
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
        // if (xtoken == CNODE_TOKEN_ADDRESS) {
        //     //balance *= 1 ether;
        // }
        uint reward = (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
        
        // Update sign of account
        account.rewardCursor = _encodeFloat(rewardPerToken);
        //channel.accounts[to] = account;

        // Transfer CoFi to account
        if (reward > 0) {
            FortToken(FORT_TOKEN_ADDRESS).mint(to, reward);
        }
    }

    // Update the global dividend information and return the new unit token dividend amount
    function _updateReward(StakeChannel storage channel) private returns (uint rewardPerToken) {
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;
        
        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }

        // Update the dividend value of unit share
        channel.rewardPerToken = _encodeFloat(rewardPerToken);
        // Update settled block number
        channel.blockCursor = uint32(block.number);
    }

    // Calculate new reward
    function _calcReward(StakeChannel storage channel) private view returns (uint newReward) {
        uint blockNumber = channel.endblock;
        if (blockNumber > block.number) {
            blockNumber = block.number;
        }
        uint blockCursor = uint(channel.blockCursor);
        if (blockNumber > blockCursor) {
            newReward =
                (blockNumber - blockCursor)
                * _reduction(block.number - FORT_GENESIS_BLOCK) 
                * _fortUnit
                * channel.weight
                / 400 ;
        }
        newReward = 0;
    }

    /// @dev Calculate dividend data
    /// @param xtoken xtoken address (or CNode address)
    /// @return newReward Amount added since last settlement
    /// @return rewardPerToken New number of unit token dividends
    function calcReward(address xtoken, uint96 cycle) external view override returns (
        uint newReward, 
        uint rewardPerToken
    ) {
        // Load staking channel
        StakeChannel storage channel = _channels[_getKey(xtoken, cycle)];
        // Call _calcReward() to calculate new reward
        newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;

        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
    }

    // CoFi ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant FORT_REDUCTION_SPAN = 2400000;
    // The decay limit of CoFi ore drawing becomes stable after exceeding this interval. 24 million blocks, about 4 years
    uint constant FORT_REDUCTION_LIMIT = 9600000; // FORT_REDUCTION_SPAN * 4;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant FORT_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _reduction(uint delta) private pure returns (uint) {
        
        if (delta < FORT_REDUCTION_LIMIT) {
            return (FORT_REDUCTION_STEPS >> ((delta / FORT_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (FORT_REDUCTION_STEPS >> 64) & 0xFFFF;
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
}
