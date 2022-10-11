// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./libs/ABDKMath64x64.sol";
import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev Options
contract NestBlindBox is NestFrequentlyUsed, ERC721 {

    uint constant NEST_AMOUNT = 99.9 ether;

    constructor() ERC721("NestBlindBox", "NestBlindBox") {
    }

    // Roll dice44 structure
    struct MintRequest {
        address owner;
        uint32 openBlock;
    }

    // The span from current block to hash block
    uint constant OPEN_BLOCK_SPAN = 1;

    uint constant P_SPACE = 1000000;
    uint constant P_99800 = P_SPACE - 1000;
    uint constant P_9900 = P_99800 - 10000;
    uint constant P_4950 = P_9900 - 20000;
    uint constant P_990 = P_4950 - 100000;
    uint constant P_495 = P_990 - 200000;

    // Roll dice44 array
    MintRequest[] _mintRequests;

    function directMint(address to, uint tokenId) external onlyGovernance {
        _mint(to, tokenId);
    }

    /// @dev start a roll dice44
    function mint() external {
        TransferHelper.safeTransferFrom(
            NEST_TOKEN_ADDRESS, 
            msg.sender, 
            address(this),
            NEST_AMOUNT
        );

        _mintRequests.push(MintRequest(msg.sender, uint32(block.number)));
    }

    /// @dev Claim gained NEST
    /// @param index index of bet
    function claim(uint index) external {
        MintRequest memory mintRequest = _mintRequests[index];
        uint hashBlock = uint(mintRequest.openBlock) + OPEN_BLOCK_SPAN;
        require(block.number > hashBlock, "NP:!hashBlock");
        uint hashValue = uint(blockhash(hashBlock));

        uint p = 0;
        if (hashValue > 0) {
            uint v = uint(keccak256(abi.encodePacked(hashValue, index))) % P_SPACE;
            if (v < P_495) {
                p = 0;
            } else if (v < P_990) {
                p = 495;
            } else if (v < P_4950) {
                p = 990;
            } else if (v < P_9900) {
                p = 4950;
            } else if (v < P_99800) {
                p = 9900;
            } else {
                p = 99800;
            }
        }

        if (p > 0) {
            _mint(mintRequest.owner, (p << 64) | index);
            console.log("mint: lev=%d, index=%d", p, index);
        }
    }
}
