# IFortOptions

## 1. Interface Description
    IFortVaultForStaking

## 2. Method Description

### 2.1. Initialize ore drawing weight

```javascript
    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param cycles cycle array
    /// @param weights weight array
    function batchSetPoolWeight(
        address[] calldata xtokens, 
        uint64[] calldata cycles, 
        uint160[] calldata weights
    ) external;
```

### 2.2. Get stake channel information

```javascript
    /// @dev Get stake channel information
    /// @param xtoken xtoken address
    /// @param cycle cycle
    /// @return totalStaked Total lock volume of target xtoken
    /// @return totalRewards Total rewards for channel
    /// @return unlockBlock Unlock block number
    function getChannelInfo(
        address xtoken, 
        uint64 cycle
    ) external view returns (
        uint totalStaked, 
        uint totalRewards,
        uint unlockBlock
    );
```

### 2.3. Get staked amount of target address

```javascript
    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, uint64 cycle, address addr) external view returns (uint);
```

### 2.4. Get the number of dcu to be collected by the target address on the designated transaction pair lock

```javascript
    /// @dev Get the number of dcu to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address
    /// @param addr Target address
    /// @return The number of dcu to be collected by the target address on the designated transaction lock
    function earned(address xtoken, uint64 cycle, address addr) external view returns (uint);
```

### 2.5. Stake xtoken to earn dcu

```javascript
    /// @dev Stake xtoken to earn dcu
    /// @param xtoken xtoken address
    /// @param amount Stake amount
    function stake(address xtoken, uint64 cycle, uint160 amount) external;
```

### 2.6. Withdraw xtoken, and claim earned dcu

```javascript
    /// @dev Withdraw xtoken, and claim earned dcu
    /// @param xtoken xtoken address
    function withdraw(address xtoken, uint64 cycle) external;
```

### 2.7. Claim dcu

```javascript
    /// @dev Claim dcu
    /// @param xtoken xtoken address
    function getReward(address xtoken, uint64 cycle) external;
```
