# IFortSwap

## 1. Interface Description
    Defines methods for FortSwap

## 2. Method Description

### 2.1. Swap for dcu with exact token amount

```javascript
    /// @dev Swap for dcu with exact token amount
    /// @param tokenAmount Amount of token
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint tokenAmount) external returns (uint dcuAmount);
```

### 2.2. Swap for token with exact dcu amount

```javascript
    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return tokenAmount Amount of token acquired
    function swapForToken(uint dcuAmount) external returns (uint tokenAmount);
```

### 2.3. Swap for exact amount of dcu

```javascript
    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount Amount of dcu expected
    /// @return tokenAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external returns (uint tokenAmount);
```

### 2.4. Swap for exact amount of token

```javascript
    /// @dev Swap for exact amount of token
    /// @param tokenAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactToken(uint tokenAmount) external returns (uint dcuAmount);
```
