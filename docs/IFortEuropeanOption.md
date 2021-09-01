# IFortEuropeanOption

## 1. Interface Description
    定义欧式期权接口

## 2. Method Description

### 2.1. 列出历史期权代币地址

```javascript
    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory optionArray);
```

### 2.2. 获取欧式期权代币地址

```javascript
    /// @dev 获取欧式期权代币地址
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 欧式期权代币地址
    function getEuropeanToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view returns (address);
```

### 2.3. 开仓

```javascript
    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint amount
    ) external payable;
```

### 2.4. 行权

```javascript
    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable;
```

### 2.5. 预估开仓可以买到的期权币数量

```javascript
    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @param oraclePrice 当前预言机价格价
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external view returns (uint amount);
```