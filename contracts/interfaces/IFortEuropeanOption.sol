// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev 欧式期权
interface IFortEuropeanOption {
    
    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory optionArray);
    
    /// @dev 获取二元期权对应的代币地址
    /// @param tokenAddress 目标代币地址
    /// @param price 行权价
    /// @param orientation 期权方向。true看涨，false看跌
    /// @param endblock 行权日期对应的区块号
    /// @return 二元期权对应的代币地址
    function getBinaryToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) external view returns (address);

    /// @dev 开仓
    /// @param tokenAddress 目前Fort系统支持ETH/USDT、NEST/ETH、COFI/ETH、HBTC/ETH
    /// @param price 用户设置的行权价格，结算时系统会根据标的物当前价与行权价比较，计算用户盈亏
    /// @param orientation 看涨/看跌2个方向
    /// @param endblock 到达该日期后用户手动进行行权，日期在系统中使用区块号进行记录
    function open(
        address tokenAddress,
        uint price,
        bool orientation,
        uint endblock,
        uint amount
    ) external payable;

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable;
}
