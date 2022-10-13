// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    /// @dev List auctions
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return auctionArray List of auctions
    function list(uint offset, uint count, uint order) external view returns (Auction[] memory auctionArray) {
        // Load auctions
        Auction[] storage auctions = _auctions;
        // Create result array
        auctionArray = new Auction[](count);
        uint length = auctions.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                auctionArray[i++] = auctions[--index];
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                auctionArray[i++] = auctions[index++];
            }
        }
    }

    // TODO: 查询历史拍卖
    // TODO: 拍卖周期，是只限定范围，还是只有几个可选的时间段。是需要确定的时间，还是折算成区块

    /// @dev Start an NFT auction
    /// @param nftAddress address of target NFT
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price
    /// @param cycle Cycle of auction, by block
    function startAuction(address nftAddress, uint tokenId, uint96 price, uint cycle) external {
        // Transfer the target NFT to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        //TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        emit StartAuction(msg.sender, nftAddress, tokenId, uint(price), _auctions.length);
        // Push auction information to the array
        _auctions.push(Auction(nftAddress, uint32(block.number + cycle), tokenId, msg.sender, price));
    }

    /// @dev Bid for the auction
    /// @param index Index of target auction
    /// @param price Bid price
    function bid(uint index, uint96 price) external {
        // Load target auction
        Auction memory auction = _auctions[index];
        // Must auctioning
        require(block.number <= uint(auction.endBlock), "AUCTION:ended");
        // Price must gt last price
        require(price > uint(auction.price), "AUCTION: price too low");
        
        // TODO: 重入问题
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, auction.bidder, (uint(price) + uint(auction.price)) >> 1);
        
        auction.bidder = msg.sender;
        auction.price = price;
        _auctions[index] = auction;

        emit Bid(index, msg.sender, uint(price));
    }

    /// @dev End the auction and get NFT
    /// @param index Index of target auction
    function endAuction(uint index) external {
        Auction memory auction = _auctions[index];
        require(block.number > uint(auction.endBlock), "AUCTION:not end");
        
        IERC721(auction.nftAddress).transferFrom(address(this), auction.bidder, auction.tokenId);

        emit EndAuction(index, msg.sender);
    }
}
