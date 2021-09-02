// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./interfaces/IFortLever.sol";

import "./FortFrequentlyUsed.sol";
import "./FortToken.sol";
import "./FortLeverToken.sol";

/// @dev 杠杆币交易
contract FortLever is FortFrequentlyUsed, IFortLever {
    
    // 最小余额数量，余额小于此值会被清算
    uint constant MIN_VALUE = 1 ether;

    // 买入杠杆币和其他交易之间最小的间隔区块数
    uint constant MIN_PERIOD = 10;

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

    /// @dev 创建杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    function create(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external override {

        bytes32 key = _getKey(tokenAddress, lever, orientation);
        address leverAddress = _leverMapping[key];
        require(leverAddress == address(0), "FortLever:exists");

        // 代币命名问题
        // string memory name = StringHelper.stringConcat(
        //     StringHelper.stringConcat(
        //         StringHelper.stringConcat(
        //             tokenAddress == address(0) ? "ETH" : StringHelper.toUpper(
        //                 StringHelper.substring(ERC20(tokenAddress).symbol(), 0, 4)
        //             ),
        //             "/USDT"
        //         ),
        //         orientation ? "+F" : "-F"
        //     ),
        //     StringHelper.toString(lever, 1)
        // );

        bytes memory buf = new bytes(31);
        uint index = 0;
        index = StringHelper.writeString(
            buf,
            index,
            tokenAddress == address(0) ? "ETH" : StringHelper.toUpper(ERC20(tokenAddress).symbol()),
            0, 
            4
        );
        index = StringHelper.writeString(buf, index, orientation ? "/USDT+F" : "/USDT-F", 0, 7);
        index = StringHelper.writeUIntDec(buf, index, lever, 1);
        string memory name = string(StringHelper.segment(buf, 0, index));

        leverAddress = address(new FortLeverToken(
            name,
            USDT_TOKEN_ADDRESS,
            tokenAddress, 
            lever, 
            orientation
        ));
        // 使用create2创建合约，会导致杠杆币内不能使用immutable变量来保存杠杆信息，从而增加gas消耗，放弃此方法
        // leverAddress = address(new FortLeverToken { 
        //         salt: keccak256(abi.encodePacked(tokenAddress, lever, orientation)) 
        //     } (
        //         StringHelper.stringConcat("LEVER-", StringHelper.toString(_levers.length)),
        //         tokenAddress, 
        //         lever, 
        //         orientation
        //     )
        // );
        
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
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @return 杠杆币地址
    function getLeverToken(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (address) {
        return _leverMapping[_getKey(tokenAddress, lever, orientation)];
        // 使用create2创建合约，会导致杠杆币内不能使用immutable变量来保存杠杆信息，从而增加gas消耗，放弃此方法
        // return 
        // address(uint160(uint(keccak256(abi.encodePacked(
        //     bytes1(0xff),
        //     address(this),
        //     keccak256(abi.encodePacked(tokenAddress, lever, orientation)),
        //     keccak256(abi.encodePacked(
        //         type(FortLeverToken).creationCode,
        //         abi.encode(tokenAddress, lever, orientation)
        //     ))
        // )))));
    }

    /// @dev 买入杠杆币
    /// @param tokenAddress 杠杆币的标的地产代币地址，0表示eth
    /// @param lever 杠杆倍数
    /// @param orientation 看涨/看跌两个方向。true：看涨，false：看跌
    /// @param fortAmount 支付的fort数量
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint fortAmount
    ) external payable override {

        require(fortAmount >= 100 ether, "FortLever:at least 100 FORT");
        // 1. 找到杠杆代币地址
        address leverAddress = _leverMapping[_getKey(tokenAddress, lever, orientation)];
        require(leverAddress != address(0), "FortLever:not exist");

        // 2. 销毁用户的fort
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 3. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(leverAddress).mint { 
            value: msg.value 
        } (msg.sender, leverAmount, block.number + MIN_PERIOD, msg.sender);
    }

    /// @dev 买入杠杆币
    /// @param leverAddress 目标杠杆币地址
    /// @param fortAmount 支付的fort数量
    function buyDirect(
        address leverAddress,
        uint fortAmount
    ) external payable override {

        require(fortAmount >= 100 ether, "FortLever:at least 100 FORT");

        // 1. 销毁用户的fort
        FortToken(FORT_TOKEN_ADDRESS).burn(msg.sender, fortAmount);

        // 2. 给用户分发杠杆币
        uint leverAmount = fortAmount;
        FortLeverToken(leverAddress).mint { 
            value: msg.value 
        } (msg.sender, leverAmount, block.number + MIN_PERIOD, msg.sender);
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
        } (account, MIN_VALUE, msg.sender);

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

    // TODO: 主动触发更新的人，按照区块奖励FORT
    /// @dev 触发更新价格，获取FORT奖励
    /// @param leverAddress 目标杠杆币地址
    /// @param payback 多余的预言机费用退回地址
    function updateLeverInfo(
        address leverAddress, 
        address payback
    ) external payable override {
        uint blocks = FortLeverToken(leverAddress).update(payback);
        FortToken(FORT_TOKEN_ADDRESS).mint(msg.sender, blocks * 1 ether);
    }

    // 根据杠杆信息计算索引key
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
    }
}
