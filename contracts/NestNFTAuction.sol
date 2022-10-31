// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev Auction for NFT
contract NestNFTAuction is NestFrequentlyUsed {

    /// @dev Start an auction event
    /// @param owner Owner of auction
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 4 decimals
    /// @param index Index of auction
    event StartAuction(address owner, uint tokenId, uint price, uint index);

    /// @dev Bid for the auction event
    /// @param index Index of target auction
    /// @param bidder Address of bidder
    /// @param price Bid price, 4 decimals
    event Bid(uint index, address bidder, uint price);

    /// @dev End the auction and get NFT event
    /// @param index Index of target auction
    /// @param sender Address of sender
    event EndAuction(uint index, address sender);

    // Auction information structure
    struct Auction {
        // Address index of bidder
        address bidder;
        // Price of last bidder, by nest, 0 decimal
        uint32 price;
        // Total bidder reward, by nest, 0 decimal
        uint32 reward;
        // The timestamp of uint32 can be expressed to 2106
        uint32 endTime;

        // Address index of owner
        address owner;
        // Token id of target nft
        uint32 tokenId;
        // Block number of start auction
        uint32 startBlock;
    }

    // Price unit
    uint constant PRICE_UNIT = 0.01 ether;

    // All auctions
    Auction[] _auctions;

    constructor() {
    }

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

    /// @dev Start an NFT auction
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 0 decimals
    /// @param cycle Cycle of auction, by seconds
    function startAuction(uint tokenId, uint32 price, uint cycle) external {
        require(tokenId < 0x100000000, "AUCTION:tokenId to large");
        require(price >= 990, "AUCTION:price too low");
        require(cycle >= 1 hours && cycle < 1 weeks, "AUCTION:cycle not valid");
        
        // Transfer the target NFT to this contract
        IERC721(CYBER_INK_ADDRESS).transferFrom(msg.sender, address(this), tokenId);
        //TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        emit StartAuction(msg.sender, tokenId, uint(price), _auctions.length);

        // Push auction information to the array
        _auctions.push(Auction(
            // bidder
            address(0),
            // price
            price,
            // reward
            uint32(0),
            // endTime
            uint32(block.timestamp + cycle),

            // owner
            msg.sender,
            // tokenId
            uint32(tokenId),
            // startBlock
            uint32(block.number)
        ));
    }

    /// @dev Bid for the auction
    /// @param index Index of target auction
    /// @param price Bid price, 0 decimals
    function bid(uint index, uint32 price) external {
        // Load target auction
        Auction storage auction = _auctions[index];

        uint32 lastPrice = auction.price;
        address bidder = auction.bidder;

        // Must auctioning
        require(block.timestamp <= uint(auction.endTime), "AUCTION:ended");
        // Price must gt last price
        require(price >= lastPrice + 1 ether / PRICE_UNIT, "AUCTION:price too low");
        
        // Only transfer NEST, no Reentry problem
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price) * PRICE_UNIT);
        // Owner has no reward, bidder is 0 means no bidder
        if (bidder != address(0)) {
            TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, bidder, (uint(price + lastPrice) >> 1) * PRICE_UNIT);
            // price + lastPrice and price - lastPrice is always the same parity, 
            // So it's no need to consider the problem of dividing losses
            auction.reward += ((price - lastPrice) >> 1);
        }

        // Update bid information: new bidder, new price, total reward
        auction.bidder = msg.sender;
        auction.price = price;

        emit Bid(index, msg.sender, uint(price));
    }

    /// @dev End the auction and get NFT
    /// @param index Index of target auction
    function endAuction(uint index) external {
        Auction memory auction = _auctions[index];
        //require(block.timestamp > uint(auction.endTime), "AUCTION:not end");
        address owner = auction.owner;
        // owner is 0 means ended
        require(owner != address(0), "AUCTION:ended");

        address bidder = auction.bidder;
        // No bidder, auction failed, transfer nft to owner
        if (bidder == address(0)) {
            bidder = owner;
        } 
        // Auction success, transfer nft to bidder and transfer nest to owner
        else {
            TransferHelper.safeTransfer(
                NEST_TOKEN_ADDRESS, 
                owner, 
                uint(auction.price - auction.reward) * PRICE_UNIT
            );
        }

        // Mark as ended
        auction.owner = address(0);

        IERC721(CYBER_INK_ADDRESS).transferFrom(address(this), bidder, uint(auction.tokenId));
        emit EndAuction(index, msg.sender);
    }
}
