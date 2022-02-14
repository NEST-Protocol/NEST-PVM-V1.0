# IHedgeOptions

## 1. Interface Description
    Define methods for european option

## 2. Method Description

### 2.1. List options

```javascript
    /// @dev List options
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray Matched option array
    function list(uint offset, uint count, uint order) external view returns (OptionView[] memory optionArray);
```

### 2.2. Obtain the number of European options that have been opened

```javascript
    /// @dev Obtain the number of European options that have been opened
    /// @return Number of European options opened
    function getOptionCount() external view returns (uint);
```

### 2.3. Open option

```javascript
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
```
Note: This method may triggers the Open event, See also 3.1.

### 2.4. Exercise option

```javascript
    /// @dev Exercise option
    /// @param index Index of option
    /// @param amount Amount of option to exercise
    function exercise(uint index, uint amount) external payable;
```
Note: This method will triggers the Exercise event, See also 3.2.

### 2.5. Estimate the amount of option

```javascript
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
```

### 2.6. Find the options of the target address (in reverse order)

```javascript
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
```

### 2.7. Sell option

```javascript
    /// @dev Sell option
    /// @param index Index of option
    /// @param amount Amount of option to sell
    function sell(uint index, uint amount) external payable;
```
Note: This method will triggers the Sell event, See also 3.3.

### 2.8. Calculate option price

```javascript
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
```

## 3. Event Description

### 3.1 Option open event

```javascript
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
```

### 3.2 Option exercise event

```javascript
    /// @dev Option exercise event
    /// @param index Index of option
    /// @param amount Amount of option to exercise
    /// @param owner Owner of this option
    /// @param gain Amount of dcu gained
    event Exercise(uint index, uint amount, address owner, uint gain);
```

### 3.3 Option sell event

```javascript
    /// @dev Option sell event
    /// @param index Index of option
    /// @param amount Amount of option to sell
    /// @param owner Owner of this option
    /// @param dcuAmount Amount of dcu acquired
    event Sell(uint index, uint amount, address owner, uint dcuAmount);
```