// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Futures
interface INestFutures {
    
    struct FutureView {
        uint index;
        address tokenAddress;
        uint lever;
        bool orientation;
        
        uint balance;
        // Base price
        uint basePrice;
        // Base block
        uint baseBlock;
    }

    /// @dev New future event
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param index Index of the future
    event New(
        address tokenAddress, 
        uint lever,
        bool orientation,
        uint index
    );

    /// @dev Buy future event
    /// @param index Index of future
    /// @param nestAmount Amount of paid NEST
    event Buy(
        uint index,
        uint nestAmount,
        address owner
    );

    /// @dev Sell future event
    /// @param index Index of future
    /// @param amount Amount to sell
    /// @param owner The owner of future
    /// @param value Amount of NEST obtained
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );

    /// @dev Settle future event
    /// @param index Index of future
    /// @param addr Target address
    /// @param sender Address of settler
    /// @param reward Liquidation reward
    event Settle(
        uint index,
        address addr,
        address sender,
        uint reward
    );
    
    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    /// @param addr Target address
    function balanceOf(uint index, uint oraclePrice, address addr) external view returns (uint);

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (FutureView[] memory futureArray);

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);

    /// @dev Create future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param levers Levers of future
    /// @param orientation true: call, false: put
    function create(address tokenAddress, uint[] calldata levers, bool orientation) external;

    /// @dev Obtain the number of futures that have been created
    /// @return Number of futures created
    function getFutureCount() external view returns (uint);

    /// @dev Get information of future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @return Information of future
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (FutureView memory);

    /// @dev Buy future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint nestAmount
    ) external payable;

    /// @dev Buy future direct
    /// @param index Index of future
    /// @param nestAmount Amount of paid NEST
    function buyDirect(uint index, uint nestAmount) external payable;

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell(uint index, uint amount) external payable;

    /// @dev Settle future
    /// @param index Index of future
    /// @param addresses Target addresses
    function settle(uint index, address[] calldata addresses) external payable;

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 2000 USD)
    /// @param bn0 Block number of the price p0
    /// @param p Latest price (number of tokens equivalent to 2000 USD)
    /// @param bn The block number of the price p
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) external view returns (uint k);

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in NEST
    /// @return Impact cost
    function impactCost(uint vol) external pure returns (uint);
}
