# IHedgeOptions

## 1. Interface Description
    定义欧式期权接口

## 2. Method Description

### 2.1. 列出历史期权信息

```javascript
    /// @dev 列出历史期权信息
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray 期权信息列表
    function list(uint offset, uint count, uint order) external view returns (OptionView[] memory optionArray);
```

### 2.2. 获取已经开通的欧式期权代币数量

```javascript
    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getOptionCount() external view returns (uint);
```

### 2.3. 获取期权信息

```javascript
    /// @dev 获取期权信息
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param strikePrice 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param exerciseBlock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return 期权信息
    function getOptionInfo(
        address tokenAddress, 
        uint strikePrice, 
        bool orientation, 
        uint exerciseBlock
    ) external view returns (OptionView memory);
```

### 2.4. 开仓

```javascript
    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param strikePrice 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param exerciseBlock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param dcuAmount 支付的dcu数量
    function open(
        address tokenAddress,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external payable;
```
Note: This method may triggers the New event and Open event, See also 3.1 and 3.2.

### 2.5. 行权

```javascript
    /// @dev 行权
    /// @param index 期权编号
    /// @param amount 结算的期权分数
    function exercise(uint index, uint amount) external payable;
```
Note: This method will triggers the Exercise event, See also 3.3.

### 2.6. 预估开仓可以买到的期权币数量

```javascript
    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param oraclePrice 当前预言机价格价
    /// @param strikePrice 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param exerciseBlock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param dcuAmount 支付的dcu数量
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external view returns (uint amount);
```

### 2.7. 查找目标账户的期权（倒序）

```javascript
    /// @dev 查找目标账户的期权（倒序）
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return optionArray 期权信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (OptionView[] memory optionArray);
```

### 2.8. 卖出期权

```javascript
    /// @dev 卖出期权
    /// @param index 期权编号
    /// @param amount 卖出的期权分数
    function sell(uint index, uint amount) external payable;
```

### 2.9. 计算期权价格

```javascript
    /// @dev 计算期权价格
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param oraclePrice 当前预言机价格价
    /// @param strikePrice 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param exerciseBlock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @return v 期权价格，需要除以18446744073709551616000000
    function calcV(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock
    ) external view returns (uint v);
```

## 3. Event Description

### 3.1 新期权事件

```javascript
    /// @dev 新期权事件
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param strikePrice 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param exerciseBlock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param index 期权编号
    event New(address tokenAddress, uint strikePrice, bool orientation, uint exerciseBlock, uint index);
```

### 3.2 开仓事件

```javascript
    /// @dev 开仓事件
    /// @param index 期权编号
    /// @param dcuAmount 支付的dcu数量
    /// @param owner 所有者
    /// @param amount 买入份数
    event Open(
        uint index,
        uint dcuAmount,
        address owner,
        uint amount
    );
```

### 3.3 行权事件

```javascript
    /// @dev 行权事件
    /// @param index 期权编号
    /// @param amount 结算的期权分数
    /// @param owner 所有者
    /// @param gain 赢得的dcu数量
    event Exercise(uint index, uint amount, address owner, uint gain);
```

### 3.4 卖出事件

```javascript
    /// @dev 卖出事件
    /// @param index 期权编号
    /// @param amount 卖出份数
    /// @param owner 所有者
    /// @param dcuAmount 得到的dcu数量
    event Sell(uint index, uint amount, address owner, uint dcuAmount);
```