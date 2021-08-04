// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./FortToken.sol";
import "./BinaryOptionToken.sol";

/// @dev 二元期权
contract FortBinary {
    
    mapping(bytes32=>address) _options;
    address _fortToken;
    address _nestPriceFacade;

    constructor() {
    }

    function setFortToken(address fortToken) external {
        _fortToken = fortToken;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
    }

    function getBinaryToken(
        address tokenAddress, 
        uint price, 
        bool orientation, 
        uint endblock
    ) public view returns (address) {
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        return _options[key];
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
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, price, orientation, endblock));
        address option = _options[key];
        if (option == address(0)) {
            option = address(new BinaryOptionToken(tokenAddress, uint88(endblock), orientation, price));
            _options[key] = option;
        }

        // TODO: 计算fortAmount
        uint fortAmount = amount;
        //TransferHelper.safeTransferFrom(_fortToken, msg.sender, address(this), fortAmount);
        FortToken(_fortToken).burn(msg.sender, fortAmount);
        BinaryOptionToken(option).mint(msg.sender, amount);
    }

    /// @dev 结算
    /// @param optionAddress 期权合约地址
    /// @param amount 结算的期权分数
    function settle(
        address optionAddress,
        uint amount
    ) external payable {

        // 检查价格
        // 计算结算结果
        (
            address tokenAddress, 
            uint endblock, 
            bool orientation, 
            uint price
        ) = BinaryOptionToken(optionAddress).getOptionInfo();

        BinaryOptionToken(optionAddress).burn(msg.sender, amount);

        // 读取预言机在指定区块的价格
        (
            uint blockNumber, 
            uint oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).findPrice {
            value: msg.value
        } (
            tokenAddress, 
            endblock, 
            msg.sender
        );

        uint gain = 0;
        // 看涨期权
        if (orientation) {
            // 赌对了
            if (oraclePrice > price) {
                // TODO: 计算赢得的fort
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
                // TODO: 计算赢得的fort
                gain = amount * (price - oraclePrice) / 1 ether;
            }
            // 赌错了
            else {

            }
        }

        if (gain > 0) {
            FortToken(_fortToken).mint(msg.sender, gain);
        }
    }
}
