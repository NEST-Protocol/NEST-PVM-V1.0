// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortLever.sol";

import "./FortToken.sol";
import "./FortLeverToken.sol";

/// @dev 杠杆币交易
contract FortLever is IFortLever {
    
    // 期权代币映射
    mapping(bytes32=>address) _leverMapping;

    // 期权代币数组
    address[] _options;

    // fort代币地址
    address _fortToken;

    // INestPriceFacade地址
    address _nestPriceFacade;

    constructor() {
    }

    function setFortToken(address fortToken) external {
        _fortToken = fortToken;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
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

    /// @dev 获取杠杆币信息
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) public view override returns (address) {
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

        // // 2. 获取预言机价格
        // (
        //     uint blockNumber, 
        //     uint oraclePrice
        // ) = INestPriceFacade(_nestPriceFacade).triggeredPrice {
        //     value: msg.value
        // } (
        //     tokenAddress, 
        //     msg.sender
        // );

        // 1. 找到杠杆代币地址
        bytes32 key = keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        address option = _leverMapping[key];
        if (option == address(0)) {
            option = address(new FortLeverToken(tokenAddress, lever, orientation));
            FortLeverToken(option).setNestPriceFacade(_nestPriceFacade);
            _leverMapping[key] = option;
            _options.push(option);
        }

        console.log("option:", option);
        console.log("_fortToken:", _fortToken);

        // 3. 收取用户的fort
        FortToken(_fortToken).burn(msg.sender, fortAmount);
        console.log("burn");
        // // 3. 给用户分发持仓凭证
        // Order[] storage orders = _orders;
        // _accounts[msg.sender].orders.push(uint64(orders.length));
        // orders.push(Order(
        //     msg.sender,
        //     uint88(lever),
        //     orientation,
        //     tokenAddress,
        //     uint96(bond),
        //     oraclePrice
        // ));

        // 4. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(option).mint { value: msg.value } (msg.sender, leverAmount);
    }

    /// @dev 卖出杠杆币
    /// @param leverAddress 目标合约地址
    /// @param amount 卖出数量
    function sell(
        address leverAddress,
        uint amount
    ) external payable override {
        // Order storage order = _orders[index];
        // require(msg.sender == order.owner, "FortPerpetual: must owner");

        // uint orderBond = uint(order.bond);
        // // 扣除保证金
        // order.bond = uint96(orderBond - bond);

        // // 计算收益
        // uint earned = 0;
        
        // FortToken(_fortToken).mint(msg.sender, earned);

        // // 1. 获取预言机价格
        // (
        //     uint blockNumber, 
        //     uint oraclePrice
        // ) = INestPriceFacade(_nestPriceFacade).triggeredPrice {
        //     value: msg.value
        // } (
        //     FortLeverToken(leverAddress).getTokenAddress(), 
        //     msg.sender
        // );

        console.log("sell-amount", amount);
        // 2. 销毁用户的杠杆币
        uint fortAmount = FortLeverToken(leverAddress).burn { value: msg.value }(msg.sender, amount);
        console.log("sell-fortAmount", fortAmount);

        // 3. 跟用户分发fort
        FortToken(_fortToken).mint(msg.sender, fortAmount);
    }

    /// @dev 清算
    /// @param leverAddress 目标合约地址
    /// @param account 清算账号
    function settle(
        address leverAddress,
        address account
    ) external payable override {
        // 2. 销毁用户的杠杆币
        uint fortAmount = FortLeverToken(leverAddress).settle { value: msg.value }(account);
        console.log("sell-fortAmount", fortAmount);

        // 3. 跟用户分发fort
        FortToken(_fortToken).mint(msg.sender, fortAmount);
    } 
}
