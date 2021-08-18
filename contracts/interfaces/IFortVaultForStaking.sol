// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Stake xtoken or CNode, earn CoFi
interface IFortVaultForStaking {

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(address[] calldata xtokens, uint96[] calldata cycles, uint[] calldata weights) external;

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return cofiPerBlock Mining speed, cofi per block
    function getChannelInfo(address xtoken, uint96 cycle) external view returns (uint totalStaked, uint cofiPerBlock);

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint96 cycle, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint96 cycle, uint amount) external;

    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken, uint96 cycle) external;

    /// @dev Calculate dividend data
    /// @param xtoken xtoken address (or CNode address)
    /// @return newReward Amount added since last settlement
    /// @return rewardPerToken New number of unit token dividends
    function calcReward(address xtoken, uint96 cycle) external view returns (
        uint newReward, 
        uint rewardPerToken
    );
}
