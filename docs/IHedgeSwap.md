# IHedgeSwap

## 1. Interface Description
    Defines methods for HedgeSwap

## 2. Method Description

### 2.1. Swap for dcu with exact nest amount

```javascript
    /// @dev Swap for dcu with exact nest amount
    /// @param nestAmount Amount of nest
    /// @return dcuAmount Amount of dcu acquired
    function swapForDCU(uint nestAmount) external returns (uint dcuAmount);
```

### 2.2. Swap for token with exact dcu amount

```javascript
    /// @dev Swap for token with exact dcu amount
    /// @param dcuAmount Amount of dcu
    /// @return nestAmount Amount of token acquired
    function swapForNEST(uint dcuAmount) external returns (uint nestAmount);
```

### 2.3. Swap for exact amount of dcu

```javascript
    /// @dev Swap for exact amount of dcu
    /// @param dcuAmount amount of dcu expected
    /// @return nestAmount Amount of token paid
    function swapExactDCU(uint dcuAmount) external returns (uint nestAmount);
```

### 2.4. Swap for exact amount of token

```javascript
    /// @dev Swap for exact amount of token
    /// @param nestAmount Amount of token expected
    /// @return dcuAmount Amount of dcu paid
    function swapExactNEST(uint nestAmount) external returns (uint dcuAmount);
```
