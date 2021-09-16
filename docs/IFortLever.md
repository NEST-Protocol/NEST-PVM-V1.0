# IFortEuropeanOption

## 1. Interface Description
    定义杠杆币交易接口

## 2. Method Description

### 2.1. 列出历史杠杆币地址

```javascript
    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory leverArray);
```

### 2.2. 获取杠杆币地址

```javascript

    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;
```

### 2.3. 获取杠杆币地址

```javascript
    /// @dev 获取杠杆币地址
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (address);
```

### 2.4. 买入杠杆币

```javascript
    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable;
```

### 2.5. 买入杠杆币

```javascript
    /// @dev 买入杠杆币
    /// @param leverAddress 目标杠杆币地址
    /// @param fortAmount 支付的fort数量
    function buyDirect(
        address leverAddress,
        uint fortAmount
    ) external payable;
```

### 2.6. 卖出杠杆币

```javascript
    /// @dev 清算
    /// @param leverAddress 目标杠杆币地址
    /// @param account 清算账号
    function settle(
        address leverAddress,
        address account
    ) external payable;
```

### 2.7. 清算

```javascript
    /// @dev 清算
    /// @param leverAddress 目标杠杆币地址
    /// @param addresses 清算目标账号数组
    function settle(
        address leverAddress,
        address[] calldata addresses
    ) external payable;
```

### 2.8. 触发更新价格，获取FORT奖励

```javascript
    /// @dev 触发更新价格，获取FORT奖励
    /// @param leverAddressArray 要更新的杠杆币合约地址
    /// @param payback 多余的预言机费用退回地址
    function updateLeverInfo(
        address[] memory leverAddressArray, 
        address payback
    ) external payable;
```