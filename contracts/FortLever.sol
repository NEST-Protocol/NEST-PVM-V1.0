// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortLever.sol";

import "./FortFrequentlyUsed.sol";
import "./FortToken.sol";
import "./FortLeverToken.sol";

/// @dev 杠杆币交易
contract FortLever is FortFrequentlyUsed, IFortLever {
    
    // 杠杆币映射
    mapping(bytes32=>address) _leverMapping;

    // 杠杆币数组
    address[] _levers;

    constructor() {
    }

    /// @dev 列出历史杠杆币地址
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return leverArray List of price sheets
    function list(uint offset, uint count, uint order) external view override returns (address[] memory leverArray) {

        // 加载代币数组
        address[] storage levers = _levers;
        // 创建结果数组
        leverArray = new address[](count);

        uint i = 0;
        // 倒序
        if (order == 0) {
            uint end = levers.length - offset - 1;
            while (i < count) {
                leverArray[i] = levers[end - i];
                ++i;
            }
        } 
        // 正序
        else {
            while (i < count) {
                leverArray[i] = levers[i + offset];
                ++i;
            }
        }
    }

    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
    }
    
    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external override {

        bytes32 key = _getKey(tokenAddress, lever, orientation);
        address leverAddress = _leverMapping[key];
        require(leverAddress == address(0), "FortLever: exists");

        // TODO: 代币命名问题
        leverAddress = address(new FortLeverToken(tokenAddress, lever, orientation));
        FortLeverToken(leverAddress).setNestPriceFacade(NEST_PRICE_FACADE_ADDRESS);
        _leverMapping[key] = leverAddress;
        _levers.push(leverAddress);
    }

    /// @dev 获取已经开通的杠杆币数量
    /// @return 已经开通的杠杆币数量
    function getTokenCount() external view override returns (uint) {
        return _levers.length;
    }

    /// @dev 获取杠杆币地址
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (address) {
        return _leverMapping[_getKey(tokenAddress, lever, orientation)];
    }

    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable override {

        // 1. 找到杠杆代币地址
        address leverAddress = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        require(leverAddress != address(0), "FortLever: not exist");

        // 2. 销毁用户的fort
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 3. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(leverAddress).mint { 
            value: msg.value 
        } (msg.sender, leverAmount, msg.sender);
    }

    /// @dev 买入杠杆币
    /// @param leverAddress 目标杠杆币地址
    /// @param fortAmount 支付的fort数量
    function buyDirect(
        address leverAddress,
        uint fortAmount
    ) external payable override {

        // 1. 销毁用户的fort
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 2. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(leverAddress).mint { 
            value: msg.value 
        } (msg.sender, leverAmount, msg.sender);
    }

    /// @dev 卖出杠杆币
    /// @param leverAddress 目标杠杆币地址
    /// @param amount 卖出数量
    function sell(
        address leverAddress,
        uint amount
    ) external payable override {

        // 1. 销毁用户的杠杆币
        FortLeverToken(leverAddress).burn { 
            value: msg.value 
        } (msg.sender, amount, msg.sender);

        uint fortAmount = amount;

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
        if (fortAmount > 0) {
            FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, fortAmount);
        }
    }

    /// @dev 更新杠杆币的价格合约地址
    /// @param leverAddressArray 要更新的杠杆币合约地址
    function sync(address[] calldata leverAddressArray) external onlyGovernance {
        for (uint i = leverAddressArray.length; i > 0; ) {
            FortLeverToken(leverAddressArray[--i]).setNestPriceFacade(NEST_PRICE_FACADE_ADDRESS);
        }
    }
}
