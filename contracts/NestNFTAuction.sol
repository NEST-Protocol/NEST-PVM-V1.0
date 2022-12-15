// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/INestNFTAuction.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Auction for NFT
contract NestNFTAuction is NestFrequentlyUsed, INestNFTAuction {

    // Auction information structure
    struct Auction {
        // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
        uint bade;

        // Address index of owner
        address owner;
        // Token id of target nft
        uint32 tokenId;
        // Block number of start auction
        uint32 startBlock;
    }

    // Price unit
    uint constant PRICE_UNIT = 0.01 ether;

    // Collect to PVM vault threshold (by PRICE_UNIT)
    // TODO: 
    uint constant COLLECT_THRESHOLD = 10000;

    // All auctions
    Auction[] _auctions;

    // PVM vault temp
    uint _vault;

    constructor() {
    }

    /// @dev In order to reduce gas cost for bid() method, 
    function collect() public {
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, NEST_VAULT_ADDRESS, _vault * PRICE_UNIT);
        _vault = 0;
    }

    /// @dev List auctions
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return auctionArray List of auctions
    function list(uint offset, uint count, uint order) 
        external view override returns (AuctionView[] memory auctionArray) {
        // Load auctions
        Auction[] storage auctions = _auctions;
        // Create result array
        auctionArray = new AuctionView[](count);
        uint length = auctions.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                auctionArray[i++] = _toAuctionView(auctions[index], index);
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
                auctionArray[i++] = _toAuctionView(auctions[index], index);
                ++index;
            }
        }
    }

    /// @dev Start an NFT auction
    /// @param tokenId tokenId of target NFT
    /// @param price Starting price, 0 decimals
    /// @param cycle Cycle of auction, by seconds
    function startAuction(uint tokenId, uint price, uint cycle) external override {
        require(tokenId < 0x100000000, "AUCTION:tokenId to large");
        require(price >= 990 && price < 0x100000000, "AUCTION:price too low");
        require(cycle >= 1 hours && cycle <= 1 weeks, "AUCTION:cycle not valid");
        
        emit StartAuction(msg.sender, tokenId, uint(price), _auctions.length);

        // Push auction information to the array
        _auctions.push(Auction(
            // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
            // After 2106, block.timestamp + cycle will > 0xFFFFFFFF, 
            // This is very far away, and there will be other alternatives
            (price << 64) | (block.timestamp + cycle),

            // owner
            msg.sender,
            // tokenId
            uint32(tokenId),
            // startBlock
            uint32(block.number)
        ));

        // Transfer the target NFT to this contract
        IERC721(CYBER_INK_ADDRESS).transferFrom(msg.sender, address(this), tokenId);
    }

    /// @dev Bid for the auction
    /// @param index Index of target auction
    /// @param price Bid price, 0 decimals
    function bid(uint index, uint price) external override {
        // Load target auction
        Auction storage auction = _auctions[index];

        // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
        uint bade = auction.bade;
        uint endTime = bade & 0xFFFFFFFF;
        uint reward = (bade >> 32) & 0xFFFFFFFF;
        uint lastPrice = (bade >> 64) & 0xFFFFFFFF;
        address bidder = address(uint160(bade >> 96));

        // Must auctioning
        require(block.timestamp <= endTime, "AUCTION:ended");
        // Price must gt last price
        require(price >= lastPrice + 1 ether / PRICE_UNIT && price < 0x100000000, "AUCTION:price too low");
        
        // Only transfer NEST, no Reentry problem
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), price * PRICE_UNIT);
        // Owner has no reward, bidder is 0 means no bidder
        if (bidder != address(0)) {
            uint halfGap = (price - lastPrice) >> 1;
            
            if ((_vault += halfGap / 5) >= COLLECT_THRESHOLD) {
                collect();
            }

            TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, bidder, (lastPrice + (halfGap << 2) / 5) * PRICE_UNIT);
            
            // price + lastPrice and price - lastPrice is always the same parity, 
            // So it's no need to consider the problem of dividing losses
            reward += halfGap;
        }

        // Update bid information: new bidder, new price, total reward
        // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
        // reward is impossible > 0xFFFFFFFF
        auction.bade = (uint(uint160(msg.sender)) << 96) | (price << 64) | (reward << 32) | endTime;

        emit Bid(index, msg.sender, uint(price));
    }

    /// @dev End the auction and get NFT
    /// @param index Index of target auction
    function endAuction(uint index) external override {
        Auction memory auction = _auctions[index];
        address owner = auction.owner;
        // owner is 0 means ended
        require(owner != address(0), "AUCTION:ended");

        // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
        uint bade = auction.bade;
        require(block.timestamp > (bade & 0xFFFFFFFF), "AUCTION:not end");
        address bidder = address(uint160(bade >> 96));
        // No bidder, auction failed, transfer nft to owner
        if (bidder == address(0)) {
            bidder = owner;
        } 
        // Auction success, transfer nft to bidder and transfer nest to owner
        else {
            TransferHelper.safeTransfer(
                NEST_TOKEN_ADDRESS, 
                owner, 
                (((bade >> 64) & 0xFFFFFFFF) - ((bade >> 32) & 0xFFFFFFFF)) * PRICE_UNIT
            );
        }

        // Mark as ended
        _auctions[index].owner = address(0);

        IERC721(CYBER_INK_ADDRESS).transferFrom(address(this), bidder, uint(auction.tokenId));
        emit EndAuction(index, msg.sender);
    }

    // Convert Auction to AuctionView
    function _toAuctionView(Auction memory auction, uint index) private pure returns (AuctionView memory auctionView) {
        // Bid information: bidder(160)|price(32)|reward(32)|endTime(32)
        uint bade = auction.bade;
        auctionView = AuctionView(
            address(uint160(bade >> 96)),
            uint32(bade >> 64),
            uint32(bade >> 32),
            uint32(bade),

            auction.owner,
            auction.tokenId,
            auction.startBlock,
            uint32(index)
        );
    }
}
