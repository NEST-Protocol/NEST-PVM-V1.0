// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Stake xtoken, earn fort
interface IFortVaultForStaking {

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        address[] calldata xtokens, 
        uint64[] calldata cycles, 
        uint160[] calldata weights
    ) external;

    /// @dev Get stake channel information
    /// @param xtoken xtoken address
    /// @param cycle cycle
    /// @return totalStaked Total lock volume of target xtoken
    /// @return totalRewards 通道总出矿量
    /// @return unlockBlock 解锁区块号
    function getChannelInfo(
        address xtoken, 
        uint64 cycle
    ) external view returns (
        uint totalStaked, 
        uint totalRewards,
        uint unlockBlock
    );

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint64 cycle, address addr) external view returns (uint);

    /// @dev Get the number of fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return The number of fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint64 cycle, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn fort
    /// @param xtoken xtoken address
    /// @param amount Stake amount
    function stake(address xtoken, uint64 cycle, uint160 amount) external;

    /// @dev Withdraw xtoken, and claim earned fort
    /// @param xtoken xtoken address
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint64 cycle, uint160 amount) external;

    /// @dev Claim fort
    /// @param xtoken xtoken address
    function getReward(address xtoken, uint64 cycle) external;
}
