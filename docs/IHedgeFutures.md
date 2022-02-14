# IHedgeOptions

## 1. Interface Description
    Defines methods for Futures

## 2. Method Description

### 2.1. List futures

```javascript
    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);
```

### 2.2. Create future

```javascript
    /// @dev Create future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;
```
Note: This method will triggers the New event, See also 3.1.

### 2.3. Get information of future

```javascript
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
```

### 2.4. Buy future

```javascript
    /// @dev Buy future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param dcuAmount Amount of paid DCU
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint dcuAmount
    ) external payable;
```
Note: This method will triggers the Buy event, See also 3.2.

### 2.5. Buy future direct

```javascript
    /// @dev Buy future direct
    /// @param index Index of future
    /// @param dcuAmount Amount of paid DCU
    function buyDirect(
        uint index,
        uint dcuAmount
    ) external payable;
```

### 2.6. Sell future

```javascript
    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell(
        uint index,
        uint amount
    ) external payable;
```
Note: This method will triggers the Sell event, See also 3.3.

### 2.7. Settle future

```javascript
    /// @dev Settle future
    /// @param index Index of future
    /// @param addresses Target addresses
    function settle(
        uint index,
        address[] calldata addresses
    ) external payable;
```
Note: This method may triggers the Settle event, See also 3.4.

### 2.8. Returns the current value of the specified future

```javascript
    /// @dev Returns the current value of the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle
    /// @param addr Target address
    function balanceOf(uint index, uint oraclePrice, address addr) external view returns (uint);
```

### 2.9. Find the futures of the target address (in reverse order)

```javascript
    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched future array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (FutureView[] memory futureArray);
```

### 2.10. Obtain the number of futures that have been opened

```javascript
    /// @dev Obtain the number of futures that have been opened
    /// @return Number of futures opened
    function getFutureCount() external view returns (uint);
```

### 2.11. K value is calculated by revised volatility

```javascript
    /// @dev K value is calculated by revised volatility
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint p0, uint bn0, uint p, uint bn) external view returns (uint k);
```

## 3. Event Description

### 3.1. New future event

```javascript
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
```

### 3.2. Buy future event

```javascript
    /// @dev Buy future event
    /// @param index Index of future
    /// @param dcuAmount Amount of paid DCU
    event Buy(
        uint index,
        uint dcuAmount,
        address owner
    );
```

### 3.3. Sell future event

```javascript
    /// @dev Sell future event
    /// @param index Index of future
    /// @param amount Amount to sell
    /// @param owner The owner of future
    /// @param value Amount of dcu obtained
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );
```

### 3.4. Settle future event

```javascript
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
```