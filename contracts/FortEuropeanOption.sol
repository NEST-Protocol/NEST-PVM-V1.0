// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./FortToken.sol";
import "./FortOptionToken.sol";

/// @dev 欧式期权
contract FortEuropeanOption {
    
    // 期权代币映射
    mapping(bytes32=>address) _optionMapping;

    // 期权代币数组
    address[] _options;

    // fort代币地址
    address _fortToken;

    // INestPriceFacade地址
    address _nestPriceFacade;

    constructor() {
    }

    /// @dev 列出历史期权代币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray List of price sheets
    function list(uint offset, uint count, uint order) external view returns (address[] memory optionArray) {
        address[] storage options = _options;
        optionArray = new address[](count);
        if (order == 0) {
            uint length = options.length - 1;
            for (uint i = 0; i < count; ++i) {
                optionArray[i] = options[length - i];
            }
        } else {
            for (uint i = 0; i < count; ++i) {
                optionArray[i] = options[i];
            }
        }
    }

    function setFortToken(address fortToken) external {
        _fortToken = fortToken;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
    }

    /// @dev 获取二元期权信息
    function getBinaryToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) public view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        return _optionMapping[key];
    }

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
    ) external payable {

        // 1. 创建期权凭证token
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        address option = _optionMapping[key];
        if (option == address(0)) {
            option = address(new FortOptionToken(tokenAddress, uint88(endblock), orientation, price));
            _optionMapping[key] = option;
            _options.push(option);
        }

        // 2. TODO: 计算权利金（需要的fort数量）
        uint fortAmount = amount;

        // 3. 销毁权利金
        FortToken(_fortToken).burn(msg.sender, fortAmount);

        // 4. 分发期权凭证
        FortOptionToken(option).mint(msg.sender, amount);
    }

    /// @dev 行权
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function exercise(address optionAddress, uint amount) external payable {

        // 1. 获取期权信息
        (
            address tokenAddress, 
            uint endblock, 
            bool orientation, 
            uint price
        ) = FortOptionToken(optionAddress).getOptionInfo();

        // 2. 销毁期权
        FortOptionToken(optionAddress).burn(msg.sender, amount);

        // 3. 调用预言机获取价格
        // 读取预言机在指定区块的价格
        (
            ,//uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).findPrice {
            value: msg.value
        } (
            tokenAddress, 
            endblock, 
            msg.sender
        );

        // 4. 分情况计算用户可以获得的fort数量
        uint gain = 0;
        // 计算结算结果
        // 看涨期权
        if (orientation) {
            // 赌对了
            if (oraclePrice > price) {
                gain = amount * (oraclePrice - price) / 1 ether;
            }
            // 赌错了
            else {

            }
        } 
        // 看跌期权
        else {
            // 赌对了
            if (oraclePrice < price) {
                gain = amount * (price - oraclePrice) / 1 ether;
            }
            // 赌错了
            else {

            }
        }

        // 5. 用户赌赢了，给其增发赢得的fort
        if (gain > 0) {
            FortToken(_fortToken).mint(msg.sender, gain);
        }
    }
}
