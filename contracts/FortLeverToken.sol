// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";
import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortEuropeanOption.sol";
import "./interfaces/INestPriceFacade.sol";

import "./FortToken.sol";
import "./FortOptionToken.sol";

// import "hardhat/console.sol";
import "hardhat/console.sol";

/// @dev 杠杆币交易
contract FortLeverToken {

    // 用户账本
    struct Account {
        // 账本-价格
        uint price;
        // 账本-价格所在区块号
        uint block;
        // 账本-余额
        uint balance;
    }

    // 最后更新的价格
    uint _price;
    
    // 最后更新的区块
    uint _block;

    address immutable TOKEN_ADDRESS;

    // 杠杆倍数
    uint immutable LEVER;

    // 方向，看涨/看跌
    bool immutable ORIENTATION;

    uint constant MIN_VALUE = 1e9;

    // 期权代币映射
    mapping(address=>Account) _accounts;

    address _nestPriceFacade;

    constructor(address tokenAddress, uint lever, bool orientation) {
        TOKEN_ADDRESS = tokenAddress;
        LEVER = lever;
        ORIENTATION = orientation;
    }

    function setNestPriceFacade(address nestPriceFacade) external {
        _nestPriceFacade = nestPriceFacade;
    }

    // TODO: 控制权限
    function updateLeverInfo() public payable returns (uint blockNumber, uint oraclePrice) {
        console.log("mint", _nestPriceFacade);

        (
            blockNumber, 
            oraclePrice
        ) = INestPriceFacade(_nestPriceFacade).triggeredPrice {
            value: msg.value
        } (
            TOKEN_ADDRESS, 
            msg.sender
        );
        _price = oraclePrice;
        _block = blockNumber;
    }

    function getLeverInfo() external view returns (uint, uint) {
        return (_price, _block);
    }

    function getTokenAddress() external view returns (address) {
        return TOKEN_ADDRESS;
    }

    function balanceOf(address acc) external view returns (uint) {
        Account storage account = _accounts[acc];
        uint oraclePrice = _price;
        uint price = account.price;
        uint balance = account.balance;

        console.log("balanceOf-oraclePrice", oraclePrice);
        console.log("balanceOf-price", price);

        uint left;
        uint right;
        // 看涨
        if (ORIENTATION) {
            // // 涨了
            // if (price > oraclePrice) {
            //     //left = balance * (oraclePrice + price * LEVER) / oraclePrice;
            //     left = balance + balance * price * LEVER / oraclePrice;
            //     right = balance * LEVER;
            //     //return left - right;
            //     //return account.balance * (oraclePrice + (price - oraclePrice) * LEVER) / oraclePrice;
            // }
            // // 跌了
            // else {
            //     //left = balance * (oraclePrice + price * LEVER) / oraclePrice;
            //     left = balance + balance * price * LEVER / oraclePrice;
            //     right = balance * LEVER;
            //     //return left - right;
            //     //return account.balance * (oraclePrice - (oraclePrice - price) * LEVER) / oraclePrice;
            // }
            left = balance + balance * price * LEVER / oraclePrice;
            right = balance * LEVER;
        } 
        // 看跌
        else {
            // // 涨了
            // if (price > oraclePrice) {
            //     //left = balance * (oraclePrice + oraclePrice * LEVER) / oraclePrice;
            //     left = balance * (1 + LEVER);
            //     right = balance * price * LEVER / oraclePrice;
            //     //return left - right;
            //     //return account.balance * (oraclePrice - (price - oraclePrice) * LEVER) / oraclePrice;
            // }
            // // 跌了
            // else {
            //     //left = balance * (oraclePrice + oraclePrice * LEVER) / oraclePrice;
            //     left = balance * (1 + LEVER);
            //     right = balance * price * LEVER / oraclePrice;
            //     //return left - right;
            //     //return account.balance * (oraclePrice + (oraclePrice - price) * LEVER) / oraclePrice;
            // }
            left = balance * (1 + LEVER);
            right = balance * price * LEVER / oraclePrice;
        }

        // if (left > right + MIN_VALUE) {
        //     return left - right;
        // }
        // return 0;
        if (left > right) {
            return left - right;
        }
        return 0;
    }

    function transfer(address to, uint value) external payable {
        (uint blockNumber, uint oraclePrice) = updateLeverInfo();

        _update(msg.sender, blockNumber, oraclePrice);
        _update(to, blockNumber, oraclePrice);

        _accounts[msg.sender].balance -= value;
        _accounts[to].balance += value;
    }

    function mint(address to, uint value) external payable returns(uint) {
        (uint blockNumber, uint oraclePrice) = updateLeverInfo();
        //_update(msg.sender, blockNumber, oraclePrice);
        Account storage account = _accounts[to];
        account.balance += value;
        account.block = blockNumber;
        account.price = oraclePrice;

        // console.log("mint-balance", account.balance);
        // console.log("mint-block", account.block);
        // console.log("mint-price", account.price);

        return value;
    }

    function burn(address from, uint value) external payable returns(uint) {
        (uint blockNumber, uint oraclePrice) = updateLeverInfo();
        //console.log("burn-value", value);
        _update(from, blockNumber, oraclePrice);
        console.log("burn-value", value);
        Account storage account = _accounts[from];
        account.balance -= value;
        //account.block = block;
        //account.price = price;

        return value;
    }

    function _update(address acc, uint blockNumber, uint oraclePrice) private returns (uint balance) {
        // TODO: 结算逻辑
        Account storage account = _accounts[acc];
        uint price = account.price;
        balance = account.balance;
        // console.log("_update-ORIENTATION", ORIENTATION);
        // console.log("_update-LEVER", LEVER);
        // console.log("_update-price", price);
        // console.log("_update-oraclePrice", oraclePrice);
        // console.log("_update-account.balance", account.balance);
        // // 看涨
        // if (ORIENTATION) {
        //     // 涨了
        //     if (price > oraclePrice) {
        //         account.balance = account.balance * (oraclePrice + (price - oraclePrice) * LEVER) /oraclePrice;
        //     }
        //     // 跌了
        //     else {
        //         account.balance = account.balance * (oraclePrice - (oraclePrice - price) * LEVER) /oraclePrice;
        //     }
        // } 
        // // 看跌
        // else {
        //     // 涨了
        //     if (price > oraclePrice) {
        //         account.balance = account.balance * (oraclePrice - (price - oraclePrice) * LEVER) /oraclePrice;
        //     }
        //     // 跌了
        //     else {
        //         account.balance = account.balance * (oraclePrice + (oraclePrice - price) * LEVER) /oraclePrice;
        //     }
        // }

        uint left;
        uint right;
        // 看涨
        if (ORIENTATION) {
            left = balance + balance * price * LEVER / oraclePrice;
            right = balance * LEVER;
        } 
        // 看跌
        else {
            left = balance * (1 + LEVER);
            right = balance * price * LEVER / oraclePrice;
        }

        if (left > right) {
            balance = left - right;
        } else {
            balance = 0;
        }

        account.balance = balance;
        account.block = blockNumber;
        account.price = oraclePrice;
    }

    function settle(address acc) external payable returns (uint) {
        (uint blockNumber, uint oraclePrice) = updateLeverInfo();
        //console.log("burn-value", value);
        uint balance = _update(acc, blockNumber, oraclePrice);
        if (balance < MIN_VALUE) {
            Account storage account = _accounts[acc];
            account.balance = 0;
            account.block = 0;
            account.price = 0;

            return balance;
        }
        return 0;
    }
}
