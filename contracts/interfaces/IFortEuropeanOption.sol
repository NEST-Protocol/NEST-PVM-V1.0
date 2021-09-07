// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 定义欧式期权接口
interface IFortEuropeanOption {
    
    // 代币通道配置结构体
    struct Config {
        // 波动率
        uint96 sigmaSQ;

        // 64位二进制精度
        // 0.3/365/86400 = 9.512937595129377E-09
        // 175482725206
        int128 miu;

        // TODO: 通过数值计算过程，确定期权行权时间最大间隔
        // 期权行权时间和当前时间的最小间隔
        uint32 minPeriod;
    }

    /// @dev 修改指定代币通道的配置
    /// @param tokenAddress 目标代币地址
    /// @param config 配置对象
    function setConfig(address tokenAddress, Config calldata config) external;

    /// @dev 获取指定代币通道的配置
    /// @param tokenAddress 目标代币地址
    /// @return 配置对象
    function getConfig(address tokenAddress) external view returns (Config memory);

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory optionArray);
    
    /// @dev 获取已经开通的欧式期权代币数量
    /// @return 已经开通的欧式期权代币数量
    function getTokenCount() external view returns (uint);

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

    /// @dev 预估开仓可以买到的期权币数量
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param oraclePrice 当前预言机价格价
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    /// @return amount 预估可以获得的期权币数量
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external view returns (uint amount);

    /// @dev 开仓
    /// @param tokenAddress 目标代币地址，0表示eth
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    /// @param fortAmount 支付的fort数量
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint fortAmount
    ) external payable;

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable;
}
