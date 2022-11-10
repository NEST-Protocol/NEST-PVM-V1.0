// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/SimpleERC721.sol";
import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev NestCyberInk NFT
contract NestCyberInk is NestFrequentlyUsed, SimpleERC721 {

    // Mint request information
    struct MintRequest {
        // Owner of this request
        address owner;
        // Block number of this request
        uint32 openBlock;
        // Block number of claim, 0 means not claimed
        uint32 claimBlock;
        // Index of this request in mint request array, for find() and list() only
        uint32 index;
    }

    // NEST amount need to be paid each mint
    uint constant NEST_AMOUNT = 99.9 ether;

    // Max circulation of nft
    uint constant MAX_CIRCULATION = 1920;

    // The span from current block to hash block
    uint constant OPEN_BLOCK_SPAN = 1;

    // Total space
    uint constant P_SPACE = 1000000;

    // level1 %1
    uint constant P_1 = 10000;

    // level2 %5
    uint constant P_5 = P_1 + 50000;

    // level3 %10
    uint constant P_10 = P_5 + 100000;

    // Mint request array
    MintRequest[] _mintRequests;

    // Counter for each nft. total(24)|nft1(24)|nft2(24)|nft3(24)|ext(160)
    uint _counter;

    // Format string to generate tokenURI
    string _uriFormat;

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "NEST Cyber Ink";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "NCI";
    }

    /// @dev Set format string to generate tokenURI
    /// @param uriFormat New format string
    function setUriFormat(string memory uriFormat) external onlyGovernance {
        _uriFormat = uriFormat;
    }

    /// @dev Return total claimed for target level nft
    /// @param level 0 means total, 1  means level1, 2 means level2, 3 means level3, Other values are meaningless
    function totalClaimed(uint level) external view returns (uint) {
        //return (_counter >> (232 - level * 24)) & 0xFFFFFF;
        return (_counter >> (160 + (3 - level) * 24)) & 0xFFFFFF;
    }

    /// @dev Find the mint requests of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return requestArray Matched MintRequest array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (MintRequest[] memory requestArray) {
        requestArray = new MintRequest[](count);
        // Calculate search region
        MintRequest[] storage mintRequests = _mintRequests;
        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = mintRequests.length;
        }
        // start > maxFindCount, so end is not 0
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            MintRequest memory mintRequest = mintRequests[--start];
            if (mintRequest.owner == owner) {
                (requestArray[index++] = mintRequest).index = uint32(start);
            }
        }
    }

    /// @dev List mint requests
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return requestArray List of MintRequest
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (MintRequest[] memory requestArray) {
        // Load mint requests
        MintRequest[] storage mintRequests = _mintRequests;
        // Create result array
        requestArray = new MintRequest[](count);
        uint length = mintRequests.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                (requestArray[i++] = mintRequests[index]).index = uint32(index);
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
                (requestArray[i++] = mintRequests[index]).index = uint32(index);
                index++;
            }
        }
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Must exists
        _requireMinted(tokenId);
        string memory uriFormat = _uriFormat;
        if (bytes(uriFormat).length == 0) {
            uriFormat = "https://ipfs.io/ipfs/bafybeihi3mkgz2zoq6vg6ustlchvierbdy4hq3mdh3nh6vybnxyc4efq3m/%u/%u.json";
        }
        // Generate token uri
        return StringHelper.sprintf(
            // buffer
            new bytes(4096), 
            // format
            uriFormat, 
            abi.encode(
                // rarity of nft
                tokenId & 0xFF, 
                // index of nft
                tokenId >> 8, 
                // rarity of nft
                tokenId & 0xFF, 
                // tokenId
                tokenId
            )
        );
    }

    /// @dev Release NFT
    /// @param to Address to receive target nft
    /// @param firstTokenId First tokenId
    /// @param step Step between two id
    /// @param count Number of ntf to release
    function release(address to, uint firstTokenId, uint step, uint count) external onlyGovernance {
        _batchMint(to, firstTokenId, step, count);
    }

    /// @dev Safe release NFT
    /// @param to Address to receive target nft
    /// @param firstTokenId First tokenId
    /// @param step Step between two id
    /// @param count Number of ntf to release
    function safeRelease(address to, uint firstTokenId, uint step, uint count) external onlyGovernance {
        _batchMint(address(this), firstTokenId, step, count);
        uint tokenId = firstTokenId + step * count;
        while (firstTokenId < tokenId) {
            tokenId -= step;
            _safeTransfer(address(this), to, tokenId, "");
        }
    }

    /// @dev Create new mint request
    function mint() external {

        // Limit the number of nft. When the number of distribution reaches the upper limit, no lottery is allowed
        // The actual circulation may exceed the limit due to non collection. Ignore this problem
        require((_counter >> 232) < MAX_CIRCULATION, "NNFT:mint over");

        // Pay NEST
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this),
            NEST_AMOUNT
        );

        // Push mint request
        _mintRequests.push(MintRequest(msg.sender, uint32(block.number), 0, 0));
    }

    /// @dev If won, create corresponding NFT to owner
    /// @param index Index of target MintRequest
    function claim(uint index) external {
        // Load mint request
        MintRequest memory mintRequest = _mintRequests[index];
        // Calculate hash
        uint hashBlock = uint(mintRequest.openBlock) + OPEN_BLOCK_SPAN;

        require(block.number > hashBlock, "NNFT:!hashBlock");
        // Must not claimed
        require(mintRequest.claimBlock == 0, "NNFT:claimed");
        
        // Mark as claimed
        _mintRequests[index].claimBlock = uint32(block.number);

        uint hashValue = uint(blockhash(hashBlock));
        if (hashValue > 0) {
            // Random value
            uint v = uint(keccak256(abi.encodePacked(hashValue, index))) % P_SPACE;
            // Counter for each nft. total(24)|nft1(24)|nft2(24)|nft3(24)|ext(160)
            uint counter = _counter;
            // nft rarity: 0 means no nft 84%, 1 means nft1 1%, 2 means nft2 5%, 3 means nft3 10%
            uint rarity = 0;

            // Each 24-bits is a number for nft, the highest 24 bits are used to record the total number, which is
            // always no less than the other counts. Therefore, when adding the whole uint, only the total number
            // may overflow, and the addition will fail, so we can directly use uint addition to achieve four counts
            // The overflow problem has been solved automatically
            if (v < P_1) {
                rarity = 1;
                // index now means nft index
                index = (counter >> 208);
                // total(+1)|nft1(+1)
                _counter = counter + 0x0000010000010000000000000000000000000000000000000000000000000000;
            } else if (v < P_5) {
                rarity = 5;
                // index now means nft index
                index = (counter >> 184);
                // total(+1)|nft2(+1)
                _counter = counter + 0x0000010000000000010000000000000000000000000000000000000000000000;
            } else if (v < P_10) {
                rarity = 10;
                // index now means nft index
                index = (counter >> 160);
                // total(+1)|nft3(+1)
                _counter = counter + 0x0000010000000000000000010000000000000000000000000000000000000000;
            } else return;

            // Mint to owner, tokenId: index(24)|rarity(8)
            _mint(mintRequest.owner, ((index & 0xFFFFFF) << 8) | rarity);
        }
    }
}
