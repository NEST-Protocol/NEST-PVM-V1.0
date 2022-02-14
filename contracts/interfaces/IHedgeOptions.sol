// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Define methods for european option
interface IHedgeOptions {
    
    /// @dev Option structure for view methods
    struct OptionView {
        uint index;
        address tokenAddress;
        uint strikePrice;
        bool orientation;
        uint exerciseBlock;
        uint balance;
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
    /// @return optionArray Matched option array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (OptionView[] memory optionArray);

    /// @dev List options
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray Matched option array
    function list(uint offset, uint count, uint order) external view returns (OptionView[] memory optionArray);
    
    /// @dev Obtain the number of European options that have been opened
    /// @return Number of European options opened
    function getOptionCount() external view returns (uint);

    /// @dev Estimate the amount of option
    /// @param tokenAddress Target token address, 0 means eth
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external view returns (uint amount);

    /// @dev Open option
    /// @param tokenAddress Target token address, 0 means eth
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    function open(
        address tokenAddress,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external payable;

    /// @dev Exercise option
    /// @param index Index of option
    /// @param amount Amount of option to exercise
    function exercise(uint index, uint amount) external payable;

    /// @dev Sell option
    /// @param index Index of option
    /// @param amount Amount of option to sell
    function sell(uint index, uint amount) external payable;

    /// @dev Calculate option price
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @return v Option price. Need to divide (USDT_BASE << 64)
    function calcV(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock
    ) external view returns (uint v);
}
