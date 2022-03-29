// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Define methods for guarantee
interface IFortLPGuarantee {
    
    /// @dev Guarantee structure for view methods
    struct GuaranteeView {
        uint index;
        uint x0;
        uint y0;
        uint balance;
        address owner;
        uint32 exerciseBlock;
        uint16 tokenIndex;
    }
    
    /// @dev Option open event
    /// @param index Index of option
    /// @param dcuAmount Amount of paid DCU
    /// @param owner Owner of this option
    /// @param amount Amount of option
    event Open(
        uint index,
        uint dcuAmount,
        address owner,
        uint amount
    );

    /// @dev Option exercise event
    /// @param index Index of option
    /// @param amount Amount of option to exercise
    /// @param owner Owner of this option
    /// @param gain Amount of dcu gained
    event Exercise(uint index, uint amount, address owner, uint gain);
    
    /// @dev Option sell event
    /// @param index Index of option
    /// @param amount Amount of option to sell
    /// @param owner Owner of this option
    /// @param dcuAmount Amount of dcu acquired
    event Sell(uint index, uint amount, address owner, uint dcuAmount);

    /// @dev Returns the share of the specified option for target address
    /// @param index Index of the option
    /// @param addr Target address
    function balanceOf(uint index, address addr) external view returns (uint);

    /// @dev Find the options of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return guaranteeArray Matched guarantee array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (GuaranteeView[] memory guaranteeArray);

    /// @dev List guarantee
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return guaranteeArray Matched option array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (GuaranteeView[] memory guaranteeArray);
    
    /// @dev Obtain the number of guarantees that have been opened
    /// @return Number of guarantees opened
    function getGuaranteeCount() external view returns (uint);

    /// @dev Estimate the amount of option
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param y0 y0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function estimate(
        uint tokenIndex,
        uint x0,
        uint y0,
        uint exerciseBlock,
        uint dcuAmount
    ) external view returns (uint amount);

    /// @dev Open option
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param y0 y0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    function open(
        uint tokenIndex,
        uint x0,
        uint y0,
        uint exerciseBlock,
        uint dcuAmount
    ) external payable;

    /// @dev Exercise guarantee
    /// @param index Index of guarantee
    /// @param amount Amount of guarantee to exercise
    function exercise(uint index, uint amount) external payable;
}
