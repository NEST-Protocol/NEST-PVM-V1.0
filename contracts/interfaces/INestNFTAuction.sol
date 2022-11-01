// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Auction of NFT
interface INestNFTAuction {

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

    // Auction view
    struct AuctionView {
        // Address of bidder
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
        uint32 index;
    }

    /// @dev List auctions
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return auctionArray List of auctions
    function list(uint offset, uint count, uint order) external view returns (AuctionView[] memory auctionArray);

    /// @dev Start an NFT auction
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 0 decimals
    /// @param cycle Cycle of auction, by seconds
    function startAuction(uint tokenId, uint price, uint cycle) external;

    /// @dev Bid for the auction
    /// @param index Index of target auction
    /// @param price Bid price, 0 decimals
    function bid(uint index, uint price) external;

    /// @dev End the auction and get NFT
    /// @param index Index of target auction
    function endAuction(uint index) external;
}
