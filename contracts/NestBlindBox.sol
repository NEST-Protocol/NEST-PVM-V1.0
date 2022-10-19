// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./libs/SimpleERC721.sol";

import "./libs/TransferHelper.sol";
import "./libs/StringHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev NEST NFT
contract NestBlindBox is NestFrequentlyUsed, SimpleERC721 {

    // NEST amount need to be paid each mint
    uint constant NEST_AMOUNT = 99.9 ether;

    constructor() {
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "NEST-NFT";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "N-NFT";
    }

    // Mint request information
    struct MintRequest {
        address owner;
        uint32 openBlock;
        uint64 index;
    }

    // The span from current block to hash block
    uint constant OPEN_BLOCK_SPAN = 1;

    uint constant P_SPACE = 1000000;
    // 10% 5% 1%
    uint constant P_1 = 10000;
    uint constant P_2 = P_1 + 50000;
    uint constant P_3 = P_2 + 100000;

    // Mint request array
    MintRequest[] _mintRequests;

    // Counter for each nft. total(64)|nft1(64)|nft2(64)|nft3(64)
    uint _counter;

    // Format string to generate tokenURI
    string _uriFormat;

    // {
    // "name":"xxx",
    // "description":"yyy",
    // "image":"ipfs://QmZxLAERiNJ8SbgLYtCeTuh83PNBkSg9deftdcvNn1vUmC",
    // "extendInfo":{
    // "videoUrl":"ipfs://QmZxLAERiNJ8SbgLYtCeTuh83PNBkSg9deftdcvNn1vUmB"
    // }
    // }
    
    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public virtual override {
        super.initialize(governance);
        _uriFormat = "ipfs://nft.nest/%04u.json?uid=%u";
    }

    /// @dev Set format string to generate tokenURI
    /// @param uriFormat New format string
    function setUriFormat(string memory uriFormat) external onlyGovernance {
        _uriFormat = uriFormat;
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
                (requestArray[index++] = mintRequest).index = uint64(start);
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
                (requestArray[i++] = mintRequests[index]).index = uint64(index);
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
                (requestArray[i++] = mintRequests[index]).index = uint64(index);
                index++;
            }
        }
    }
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return StringHelper.sprintf(
            new bytes(4096), 
            _uriFormat, 
            abi.encode(tokenId >> 64, tokenId & 0xFFFFFFFFFFFFFFFF, tokenId)
        );
    }

    // Release NFT
    function release(address to, uint[] calldata tokenIdArray) external onlyGovernance {
        for (uint i = tokenIdArray.length; i > 0;) {
            _mint(to, tokenIdArray[--i]);
        }
    }

    /// @dev Create new mint request
    function mint() external {
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this),
            NEST_AMOUNT
        );

        require((_counter >> 192) < 1999, "NNFT:mint over");
        _mintRequests.push(MintRequest(msg.sender, uint32(block.number), 0));
    }

    /// @dev If won, create corresponding NFT to owner
    /// @param index Index of target MintRequest
    function claim(uint index) external {
        MintRequest memory mintRequest = _mintRequests[index];
        uint hashBlock = uint(mintRequest.openBlock) + OPEN_BLOCK_SPAN;
        require(block.number > hashBlock, "NNFT:!hashBlock");
        uint hashValue = uint(blockhash(hashBlock));

        uint p = 0;
        uint cnt = 0;
        if (hashValue > 0) {
            uint v = uint(keccak256(abi.encodePacked(hashValue, index))) % P_SPACE;
            uint counter = _counter;
            if (v < P_1) {
                p = 1;
                cnt = 0x0000000000000001000000000000000000000000000000000000000000000001;
                index = counter & 0xFFFFFFFFFFFFFFFF;
            } else if (v < P_2) {
                p = 2;
                cnt = 0x0000000000000001000000000000000000000000000000010000000000000000;
                index = (counter >> 64) & 0xFFFFFFFFFFFFFFFF;
            } else if (v < P_3) {
                p = 3;
                cnt = 0x0000000000000001000000000000000100000000000000000000000000000000;
                index = (counter >> 128) & 0xFFFFFFFFFFFFFFFF;
            } else return;

            // The overflow problem has been solved automatically
            _counter += cnt;
            _mint(mintRequest.owner, (p << 64) | index);
            console.log("mint: lev=%d, index=%d", p, index);
        }
    }
}
