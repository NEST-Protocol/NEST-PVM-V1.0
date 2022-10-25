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
    /// @param nftAddress Address of target NFT
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 4 decimals
    /// @param index Index of auction
    event StartAuction(address owner, address nftAddress, uint tokenId, uint price, uint index);

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
        // Owner of this auction
        address owner;
        // Block number of start auction
        uint32 startBlock;
        // End block of this auction
        uint64 endTime;
        // Address of target nft
        address nftAddress;
        // Token id of target nft
        uint96 tokenId;
        
        // TODO: Separate the changed parts into a structure, for saving gas
        // Address of last bidder
        address bidder;
        // Price of last bidder, by nest, 4 decimals
        uint48 price;
        // Price of total reward, by nest, 4 decimals
        uint48 reward;
    }

    // Price unit
    uint constant PRICE_UNIT = 0.0001 ether;

    // All auctions
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

    /// @dev Start an NFT auction
    /// @param nftAddress Address of target NFT
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 4 decimals
    /// @param cycle Cycle of auction, by seconds
    function startAuction(address nftAddress, uint tokenId, uint48 price, uint cycle) external {
        require(tokenId < 0x1000000000000000000000000, "AUCTION:must nest nft");
        require(cycle > 1 hours && cycle < 0x100000000, "AUCTION:cycle not valid");

        // Transfer the target NFT to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        //TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price));
        emit StartAuction(msg.sender, nftAddress, tokenId, uint(price), _auctions.length);

        // Push auction information to the array
        _auctions.push(Auction(
            msg.sender,
            uint32(block.number),
            uint64(block.timestamp + cycle),
            nftAddress,
            uint96(tokenId),
            address(0),
            price,
            uint48(0)
        ));
    }

    /// @dev Bid for the auction
    /// @param index Index of target auction
    /// @param price Bid price, 4 decimals
    function bid(uint index, uint48 price) external {
        // Load target auction
        Auction memory auction = _auctions[index];
        // Must auctioning
        require(block.timestamp <= uint(auction.endTime), "AUCTION:ended");
        // Price must gt last price
        require(price > auction.price, "AUCTION:price too low");
        
        uint48 lastPrice = auction.price;
        address bidder = auction.bidder;

        // Calculate reward
        uint48 reward = 0;
        // Owner has no reward, bidder is 0 means no bidder
        if (bidder != address(0)) {
            reward = (price - lastPrice) >> 1;
        }

        // Update bid information: new bidder, new price, total reward
        auction.bidder = msg.sender;
        auction.price = price;
        auction.reward += reward;
        _auctions[index] = auction;

        emit Bid(index, msg.sender, uint(price));

        // TODO: 是否需要限制最小差价?
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), uint(price) * PRICE_UNIT);
        if (bidder != address(0)) {
            TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, auction.bidder, (uint(lastPrice) + reward) * PRICE_UNIT);
        }
    }

    /// @dev End the auction and get NFT
    /// @param index Index of target auction
    function endAuction(uint index) external {
        Auction memory auction = _auctions[index];
        //require(block.timestamp > uint(auction.endTime), "AUCTION:not end");
        require(auction.owner != address(0), "AUCTION:ended");

        address bidder = auction.bidder;
        // No bidder, auction failed, transfer nft to owner
        if (bidder == address(0)) {
            bidder = auction.owner;
        } 
        // Auction success, transfer nft to bidder and transfer nest to owner
        else {
            TransferHelper.safeTransfer(
                NEST_TOKEN_ADDRESS, 
                auction.owner, 
                uint(auction.price - auction.reward) * PRICE_UNIT
            );
        }

        auction.owner = address(0);
        _auctions[index] = auction;

        IERC721(auction.nftAddress).transferFrom(address(this), bidder, auction.tokenId);
        emit EndAuction(index, msg.sender);
    }
}
