// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/ICommonGovernance.sol";

import "./libs/SimpleERC20.sol";

import "./common/CommonBase.sol";

/// @dev Switch old NEST to new NEST by this contract
contract NestSwitch is CommonBase {

    address OLD_NEST_TOKEN_ADDRESS;
    address NEW_NEST_TOKEN_ADDRESS;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param governance INestGovernance implementation contract address
    function update(address governance) external onlyGovernance {
        OLD_NEST_TOKEN_ADDRESS = ICommonGovernance(governance).checkAddress("nest.app.nest.old");
        NEW_NEST_TOKEN_ADDRESS = ICommonGovernance(governance).checkAddress("nest.app.nest");
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
        require(msg.sender == tx.origin, "NS:no contract");
        uint switchRecord = _switchRecords[msg.sender];
        require(switchRecord < type(uint).max, "NM:each address can only withdraw once");
        _switchRecords[msg.sender] = switchRecord + value;
        IERC20(OLD_NEST_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), value);
    }

    /// @dev User call this method to withdraw new NEST from contract
    /// @param merkleProof Merkle proof for the address
    function withdrawNew(bytes32[] calldata merkleProof) external {
        uint switchRecord = _switchRecords[msg.sender];
        require(switchRecord < type(uint).max, "NM:each address can only withdraw once");
        require(MerkleProof.verify(
            merkleProof, 
            _merkleRoot, 
            keccak256(abi.encodePacked(msg.sender))
        ), "NS:verify failed");

        IERC20(NEW_NEST_TOKEN_ADDRESS).transfer(msg.sender, switchRecord);
        _switchRecords[msg.sender] = type(uint).max;
    }
}
