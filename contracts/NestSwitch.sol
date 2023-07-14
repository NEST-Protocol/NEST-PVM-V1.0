// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/ICommonGovernance.sol";

import "./common/CommonBase.sol";

/// @dev Switch old NEST to new NEST by this contract
contract NestSwitch is CommonBase {

    address immutable OLD_NEST_TOKEN_ADDRESS;
    address immutable NEW_NEST_TOKEN_ADDRESS;

    constructor(address oldNestTokenAddress, address newNestTokenAddress) {
        OLD_NEST_TOKEN_ADDRESS = oldNestTokenAddress;
        NEW_NEST_TOKEN_ADDRESS = newNestTokenAddress;
    }

    // Merkle root for white list
    bytes32 _merkleRoot;

    mapping(address=>uint) _switchRecords;

    /// @dev Set merkle root for white list
    /// @param merkleRoot Merkle root for white list
    function setMerkleRoot(bytes32 merkleRoot) external onlyGovernance {
        _merkleRoot = merkleRoot;
    }

    /// @dev Get merkle root for white list
    /// @return Merkle root for white list
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @dev User call this method to deposit old NEST to contract
    /// @param value Value of old NEST
    function switchOld(uint value) external {
        // Contract address is forbidden
        require(msg.sender == tx.origin, "NS:forbidden!");

        // Each address can switch only once
        require(_switchRecords[msg.sender] == 0, "NS:only once!");

        // Record value of NEST to switch
        _switchRecords[msg.sender] = value;

        // Transfer old NEST to this contract from msg.sender
        TransferHelper.safeTransferFrom(OLD_NEST_TOKEN_ADDRESS, msg.sender, address(this), value);
    }

    /// @dev User call this method to withdraw new NEST from contract
    /// @param merkleProof Merkle proof for the address
    function withdrawNew(bytes32[] calldata merkleProof) external {
        // Load switch record
        uint switchRecord = _switchRecords[msg.sender];

        // type(uint).max means user has withdrawn
        require(switchRecord < type(uint).max, "NS:only once!");

        // Check if the address is released
        require(MerkleProof.verify(
            merkleProof, 
            _merkleRoot, 
            keccak256(abi.encodePacked(msg.sender))
        ), "NS:verify failed");

        // Transfer new NEST to msg.sender
        TransferHelper.safeTransfer(NEW_NEST_TOKEN_ADDRESS, msg.sender, switchRecord);

        // Mark user has withdrawn
        _switchRecords[msg.sender] = type(uint).max;
    }

    /// @dev Migrate token to governance address
    /// @param tokenAddress Address of target token
    /// @param value Value to migrate
    function migrate(address tokenAddress, uint value) external onlyGovernance {
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);
    }
}
