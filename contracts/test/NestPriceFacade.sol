// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "../interfaces/INestPriceFacade.sol";

import "hardhat/console.sol";

contract NestPriceFacade is INestPriceFacade {
    
    struct Price {
        uint price;
        uint dbn;
    }

    mapping(address=>Price) _prices;

    function setPrice(address token, uint price, uint dbn) external {
        _prices[token] = Price(price, dbn);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPriceView(address tokenAddress) public view returns (uint blockNumber, uint price) {
        //require(tokenAddress != address(0));
        //return (block.number - 1, 2700 * 1000000);

        Price memory p = _prices[tokenAddress];
        if (p.price == 0) {
            p = Price(2700 * 1000000, 1);
        }

        return (block.number - p.dbn, p.price);
    }

    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height, 
        address payback
    ) external payable override returns (uint blockNumber, uint price) {

        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "NestPriceFacade:Error fee");
        }

        // if (height > 90) {
        //     return (height - 1, 2450000000);
        // }
        return latestPriceView(tokenAddress);
    }

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress, 
        address payback
    ) external payable override returns (uint blockNumber, uint price) {

        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "NestPriceFacade:Error fee");
        }

        // if (block.number > 90) {
        //     return (block.number - 1, 450000000);
        // }
        return latestPriceView(tokenAddress);
    }

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(
        address tokenAddress, 
        address payback
    ) external payable override returns (uint blockNumber, uint price) {

        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "NestPriceFacade:Error fee");
        }

        // if (block.number > 90) {
        //     return (block.number - 1, 450000000);
        // }
        return latestPriceView(tokenAddress);
    }

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        address tokenAddress, 
        address payback
    ) external payable override returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ) {

        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "NestPriceFacade:Error fee");
        }

        (blockNumber, price) = latestPriceView(tokenAddress);
        if (tokenAddress == 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9) {
            return (blockNumber, price, price * 10000 / 10000, 10853469234);
        }
        return (blockNumber, price, price * 9500 / 10000, 10853469234);
    }

    
    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(
        address tokenAddress, 
        uint count, 
        address payback
    ) 
    external 
    payable 
    override
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        if (msg.value > 0.01 ether) {
            payable(payback).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "CoFiXController: Error fee");
        }

        return lastPriceListAndTriggeredPriceInfoView(tokenAddress, count);
    }

    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(
        address tokenAddress, 
        uint count, 
        address paybackAddress
    ) external payable override returns (uint[] memory prices) {
        if (msg.value > 0.01 ether) {
            payable(paybackAddress).transfer(msg.value - 0.01 ether);
        } else {
            require(msg.value == 0.01 ether, "CoFiXController: Error fee");
        }

        (
            prices,
            ,//uint triggeredPriceBlockNumber,
            ,//uint triggeredPriceValue,
            ,//uint triggeredAvgPrice,
            //uint triggeredSigmaSQ
        ) = lastPriceListAndTriggeredPriceInfoView(tokenAddress, count);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfoView(
        address tokenAddress, 
        uint count
    ) 
    public 
    view
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        (uint bn, uint price) = latestPriceView(tokenAddress);
        prices = new uint[](count <<= 1);
        for (uint i = 0; i < count;) {
            prices[i] = bn - i;
            //prices[i + 1] = price + i * 1.79e6;
            prices[i + 1] = price + i * 1.789e6;
            i += 2; 
        }
        return (prices, bn, price, price * 9500 / 10000, 10853469234);
    }
}