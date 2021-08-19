// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortLever.sol";

import "./FortBase2.sol";
import "./FortToken.sol";
import "./FortLeverToken.sol";

/// @dev 杠杆币交易
contract FortLever is FortBase2, IFortLever {
    
    // 期权代币映射
    mapping(bytes32=>address) _leverMapping;

    // 期权代币数组
    address[] _options;

    constructor() {
    }

    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (address[] memory leverArray) {

        address[] storage options = _options;
        leverArray = new address[](count);

        if (order == 0) {
            uint length = options.length - offset - 1;
            for (uint i = 0; i < count; ++i) {
                leverArray[i] = options[length - i];
            }
        } else {
            for (uint i = 0; i < count; ++i) {
                leverArray[i] = options[i + offset];
            }
        }
    }

    /// @dev 获取杠杆币地址
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌2个方向
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (address) {
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        return _leverMapping[key];
    }

    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌2个方向
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable override {

        // 1. 找到杠杆代币地址
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        address option = _leverMapping[key];
        if (option == address(0)) {
            option = address(new FortLeverToken(tokenAddress, lever, orientation));
            FortLeverToken(option).setNestPriceFacade(NEST_PRICE_FACADE_ADDRESS);
            _leverMapping[key] = option;
            _options.push(option);
        }

        // 2. 收取用户的fort
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 3. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(option).mint { 
            value: msg.value 
        } (msg.sender, leverAmount, msg.sender);
    }

    /// @dev 卖出杠杆币
    /// @param leverAddress 目标合约地址
    /// @param amount 卖出数量
    function sell(
        address leverAddress,
        uint amount
    ) external payable override {

        // 1. 销毁用户的杠杆币
        uint fortAmount = FortLeverToken(leverAddress).burn { 
            value: msg.value 
        } (msg.sender, amount, msg.sender);

        // 2. 给用户分发fort
        FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, fortAmount);
    }

    /// @dev 清算
    /// @param leverAddress 目标杠杆币地址
    /// @param account 清算账号
    function settle(
        address leverAddress,
        address account
    ) external payable override {

        // 1. 销毁用户的杠杆币
        uint fortAmount = FortLeverToken(leverAddress).settle { 
            value: msg.value 
        } (account, msg.sender);

        // 2. 跟用户分发fort
        FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, fortAmount);
    }

    /// @dev 更新杠杆币的价格合约地址
    /// @param leverAddressArray 要更新的杠杆币合约地址
    function sync(address[] calldata leverAddressArray) external onlyGovernance {
        for (uint i = leverAddressArray.length; i > 0; ) {
            FortLeverToken(leverAddressArray[--i]).setNestPriceFacade(NEST_PRICE_FACADE_ADDRESS);
        }
    }
}
