// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Define methods for guarantee
interface INestLPGuarantee {
    
    /// @dev Guarantee structure for view methods
    struct GuaranteeView {
        uint index;
        uint x0;
        uint y0;
        uint32 openBlock;
        uint32 exerciseBlock;
        uint16 tokenIndex;
        uint16 balance;
        address owner;
    }
    
    /// @dev Guarantee open event
    /// @param index Index of guarantee
    /// @param dcuAmount Amount of paid DCU
    /// @param owner Owner of this guarantee
    event Open(uint index, uint dcuAmount, address owner);

    /// @dev Guarantee exercise event
    /// @param index Index of guarantee
    /// @param owner Owner of this guarantee
    /// @param gain Amount of dcu gained
    event Exercise(uint index, address owner, uint gain);
    
    /// @dev Returns the share of the specified guarantee for target address
    /// @param index Index of the guarantee
    /// @param addr Target address
    function balanceOf(uint index, address addr) external view returns (uint);

    /// @dev Find the guarantees of the target address (in reverse order)
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
    /// @return guaranteeArray Matched guarantee array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (GuaranteeView[] memory guaranteeArray);
    
    /// @dev Obtain the number of guarantees that have been opened
    /// @return Number of guarantees opened
    function getGuaranteeCount() external view returns (uint);

    /// @dev Estimate the amount of dcu
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @return dcuAmount Amount of dcu
    function estimate(
        uint tokenIndex,
        uint x0,
        uint exerciseBlock
    ) external view returns (uint dcuAmount);

    /// @dev Open guarantee
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    function open(
        uint tokenIndex,
        uint x0,
        uint exerciseBlock
    ) external payable;

    /// @dev Exercise guarantee
    /// @param index Index of guarantee
    function exercise(uint index) external payable;
}
