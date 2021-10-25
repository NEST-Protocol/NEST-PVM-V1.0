# IHedgeOptions

## 1. Interface Description
    定义永续合约交易接口

## 2. Method Description

### 2.1. 列出历史永续合约地址

```javascript
    /// @dev 列出历史永续合约地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);
```

### 2.2. 创建永续合约

```javascript
    /// @dev 创建永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external;
```
Note: This method will triggers the New event, See also 3.1.

### 2.3. 获取永续合约信息

```javascript
    /// @dev 获取永续合约信息
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 永续合约地址
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (FutureView memory);
```

### 2.4. 买入永续合约

```javascript
    /// @dev 买入永续合约
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
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

### 2.5. 买入永续合约

```javascript
    /// @dev 买入永续合约
    /// @param index 永续合约编号
    /// @param dcuAmount 支付的dcu数量
    function buyDirect(
        uint index,
        uint dcuAmount
    ) external payable;
```

### 2.6. 卖出永续合约

```javascript
    /// @dev 卖出永续合约
    /// @param index 永续合约编号
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
    /// @param index 永续合约编号
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

### 2.10. 获取已经开通的永续合约数量

```javascript
    /// @dev 获取已经开通的永续合约数量
    /// @return 已经开通的永续合约数量
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

### 3.1. 新永续合约事件

```javascript
    /// @dev 新永续合约事件
    /// @param tokenAddress 永续合约的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param index 永续合约编号
    event New(
        address tokenAddress, 
        uint lever,
        bool orientation,
        uint index
    );
```

### 3.2. 买入永续合约事件

```javascript
    /// @dev 买入永续合约事件
    /// @param index 永续合约编号
    /// @param dcuAmount 支付的dcu数量
    event Buy(
        uint index,
        uint dcuAmount,
        address owner
    );
```

### 3.3. 卖出永续合约事件

```javascript
    /// @dev 卖出永续合约事件
    /// @param index 永续合约编号
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
    /// @param index 永续合约编号
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