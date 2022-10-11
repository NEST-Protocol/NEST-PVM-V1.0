// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev Options
contract NestNFTAuction is NestFrequentlyUsed {

    event StartAuction(address sender, address nftAddress, uint tokenId, uint price, uint index);
    event Bid(uint index, address bidder, uint price);
    event EndAuction(uint index, address sender);

    struct Auction {
        address nftAddress;
        uint32 endBlock;
        uint tokenId;
        address bidder;
        uint96 price;
    }

    Auction[] _auctions;

    // TODO: 查询历史拍卖

    function startAuction(address nftAddress, uint tokenId, uint96 price) external {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        //TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        emit StartAuction(msg.sender, nftAddress, tokenId, uint(price), _auctions.length);
        _auctions.push(Auction(nftAddress, uint32(block.number + 100), tokenId, msg.sender, price));
    }

    function bid(uint index, uint96 price) external {
        Auction memory auction = _auctions[index];
        require(block.number <= uint(auction.endBlock), "AUCTION:ended");
        // require(price > uint(auction.price), "AUCTION: price too low");
        
        // TODO: 重入问题
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, auction.bidder, (uint(price) + uint(auction.price)) >> 1);
        auction.bidder = msg.sender;
        auction.price = price;
        _auctions[index] = auction;

        emit Bid(index, msg.sender, uint(price));
    }

    function endAuction(uint index) external {
        Auction memory auction = _auctions[index];
        require(block.number > uint(auction.endBlock), "AUCTION:not end");
        
        IERC721(auction.nftAddress).transferFrom(address(this), auction.bidder, auction.tokenId);

        emit EndAuction(index, msg.sender);
    }
}
