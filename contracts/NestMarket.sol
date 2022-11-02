// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

import "hardhat/console.sol";

/// @dev Nest market
contract NestMarket is NestFrequentlyUsed {
    // Merkle root for white list
    bytes32 _merkleRoot;

    // Counter for each white list buy
    mapping(address=>uint) _whiteListCounter;

    /// @dev Set merkle root for white list
    /// @param merkleRoot Merkle Root for white list
    function setMerkleRoot(bytes32 merkleRoot) external onlyGovernance {
        console.log("merkleRoot: %s", uint(merkleRoot));
        _merkleRoot = merkleRoot;
    }

    /// @dev Get merkle root for white list
    /// @return Merkle Root for white list
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @dev White list address buy
    /// @param tokenId Target tokenId
    /// @param merkleProof Merkle proof for the address
    function whiteListBuy(uint tokenId, bytes32[] calldata merkleProof) external {
        uint cnt = _whiteListCounter[msg.sender];
        require(cnt < 10, "NWL:address can only buy 10");
        require(MerkleProof.verify(
            merkleProof, 
            _merkleRoot, 
            keccak256(abi.encodePacked(msg.sender))
        ), "NWL:address is not in whiteList");

        _whiteListCounter[msg.sender] = cnt + 1;
        
        // White list address pay 70% of the price
        uint price = 1000 / (tokenId >> 24) * 70 / 100 * 1 ether;
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), price);
        IERC721(CYBER_INK_ADDRESS).transferFrom(address(this), msg.sender, tokenId);
    }

    /// @dev Normal address buy
    /// @param tokenId Target tokenId
    function buy(uint tokenId) external {
        uint price = 1000 / (tokenId >> 24) * 1 ether;
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), price);
        IERC721(CYBER_INK_ADDRESS).transferFrom(address(this), msg.sender, tokenId);
    }
}
