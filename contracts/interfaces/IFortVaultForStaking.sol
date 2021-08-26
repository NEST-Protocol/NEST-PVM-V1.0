// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Stake xtoken, earn fort
interface IFortVaultForStaking {

    /// @dev Initialize ore drawing weight
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
    ) external;

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @param cycle cycle
    /// @return totalStaked Total lock volume of target xtoken
    /// @return totalRewards 通道总出矿量
    /// @return startblock 锁仓起始区块
    /// @return endblock 锁仓结束区块（达到结束区块后可以领取分红）
    function getChannelInfo(
        address xtoken, 
        uint96 cycle
    ) external view returns (
        uint totalStaked, 
        uint totalRewards,
        uint startblock,
        uint endblock
    );

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Get the number of fort to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of fort to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Withdraw xtoken, and claim earned fort
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Claim fort
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken, uint96 cycle) external;
}
