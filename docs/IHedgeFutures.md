# IHedgeOptions

## 1. Interface Description
    定义杠杆币交易接口

## 2. Method Description

### 2.1. 列出历史杠杆币地址

```javascript
    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);
```

### 2.2. 创建杠杆币

```javascript
    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;
```
Note: This method will triggers the New event, See also 3.1.

### 2.3. 获取杠杆币信息

```javascript
    /// @dev 获取杠杆币信息
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (FutureView memory);
```

### 2.4. 买入杠杆币

```javascript
    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param dcuAmount 支付的dcu数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint dcuAmount
    ) external payable;
```
Note: This method will triggers the Buy event, See also 3.2.

### 2.5. 买入杠杆币

```javascript
    /// @dev 买入杠杆币
    /// @param index 杠杆币编号
    /// @param dcuAmount 支付的dcu数量
    function buyDirect(
        uint index,
        uint dcuAmount
    ) external payable;
```

### 2.6. 卖出杠杆币

```javascript
    /// @dev 卖出杠杆币
    /// @param index 杠杆币编号
    /// @param amount 卖出数量
    function sell(
        uint index,
        uint amount
    ) external payable;
```
Note: This method will triggers the Sell event, See also 3.3.

### 2.7. 清算

```javascript
    /// @dev 清算
    /// @param index 杠杆币编号
    /// @param addresses 清算目标账号数组
    function settle(
        uint index,
        address[] calldata addresses
    ) external payable;
```
Note: This method may triggers the Settle event, See also 3.4.

### 2.8. 返回指定期权当前的价值

```javascript
    /// @dev 返回指定期权当前的价值
    /// @param index 目标期权索引号
    /// @param oraclePrice 预言机价格
    /// @param addr 目标地址
    function balanceOf(uint index, uint oraclePrice, address addr) external view returns (uint);
```

### 2.9. 查找目标账户的合约

```javascript
    /// @dev 查找目标账户的合约
    /// @param start 从给定的合约地址对应的索引向前查询（不包含start对应的记录）
    /// @param count 最多返回的记录条数
    /// @param maxFindCount 最多查找maxFindCount记录
    /// @param owner 目标账户地址
    /// @return futureArray 合约信息列表
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (FutureView[] memory futureArray);
```

### 2.10. 获取已经开通的杠杆币数量

```javascript
    /// @dev 获取已经开通的杠杆币数量
    /// @return 已经开通的杠杆币数量
    function getLeverCount() external view returns (uint);
```

## 3. Event Description

### 3.1. 新杠杆币事件

```javascript
    /// @dev 新杠杆币事件
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param index 杠杆币编号
    event New(
        address tokenAddress, 
        uint lever,
        bool orientation,
        uint index
    );
```

### 3.2. 买入杠杆币事件

```javascript
    /// @dev 买入杠杆币事件
    /// @param index 杠杆币编号
    /// @param dcuAmount 支付的dcu数量
    event Buy(
        uint index,
        uint dcuAmount,
        address owner
    );
```

### 3.3. 卖出杠杆币事件

```javascript
    /// @dev 卖出杠杆币事件
    /// @param index 杠杆币编号
    /// @param amount 卖出数量
    /// @param owner 所有者
    /// @param value 获得的dcu数量
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );
```

### 3.4. 清算事件

```javascript
    /// @dev 清算事件
    /// @param index 杠杆币编号
    /// @param addr 清算目标账号数组
    /// @param sender 清算发起账号
    /// @param reward 清算获得的dcu数量
    event Settle(
        uint index,
        address addr,
        address sender,
        uint reward
    );
```