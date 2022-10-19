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

    // Ming request information
    struct MintRequest {
        address owner;
        uint32 openBlock;
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
                requestArray[i++] = mintRequests[--index];
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
                requestArray[i++] = mintRequests[index++];
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

    // Test method
    function directMint(address to, uint tokenId) external onlyGovernance {
        _mint(to, tokenId);
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

        _mintRequests.push(MintRequest(msg.sender, uint32(block.number)));
    }

    /// @dev If won, create corresponding NFT to owner
    /// @param index Index of target MintRequest
    function claim(uint index) external {
        MintRequest memory mintRequest = _mintRequests[index];
        uint hashBlock = uint(mintRequest.openBlock) + OPEN_BLOCK_SPAN;
        require(block.number > hashBlock, "NP:!hashBlock");
        uint hashValue = uint(blockhash(hashBlock));

        uint p = 0;
        if (hashValue > 0) {
            uint v = uint(keccak256(abi.encodePacked(hashValue, index))) % P_SPACE;
            if (v < P_1) {
                p = 1;
            } else if (v < P_2) {
                p = 2;
            } else if (v < P_3) {
                p = 3;
            } else return;

            _mint(mintRequest.owner, (p << 64) | index);
            console.log("mint: lev=%d, index=%d", p, index);
        }
    }
}
