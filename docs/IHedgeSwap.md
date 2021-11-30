# IHedgeSwap

## 1. Interface Description
    定义dcu和nest兑换的接口

## 2. Method Description

### 2.1. 使用确定数量的nest兑换dcu

```javascript
    /// @dev 使用确定数量的nest兑换dcu
    /// @param nestAmount nest数量
    /// @return dcuAmount 兑换到的dcu数量
    function swapForDCU(uint nestAmount) external returns (uint dcuAmount);
```

### 2.2. 使用确定数量的dcu兑换nest

```javascript
    /// @dev 使用确定数量的dcu兑换nest
    /// @param dcuAmount dcu数量
    /// @return nestAmount 兑换到的nest数量
    function swapForNEST(uint dcuAmount) external returns (uint nestAmount);
```

### 2.3. 使用nest兑换确定数量的dcu

```javascript
    /// @dev 使用nest兑换确定数量的dcu
    /// @param dcuAmount 预期得到的dcu数量
    /// @return nestAmount 支付的nest数量
    function swapExactDCU(uint dcuAmount) external returns (uint nestAmount);
```

### 2.4. 使用dcu兑换确定数量的nest

```javascript
    /// @dev 使用dcu兑换确定数量的nest
    /// @param nestAmount 预期得到的nest数量
    /// @return dcuAmount 支付的dcu数量
    function swapExactNEST(uint nestAmount) external returns (uint dcuAmount);
```
