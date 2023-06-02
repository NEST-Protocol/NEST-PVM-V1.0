// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/SimpleERC20.sol";

import "./common/CommonBase.sol";

/// @dev Nest Token for scroll test net
contract NestToken is CommonBase, SimpleERC20 {

    uint quotaPerDay;

    mapping(uint=>uint) _drawnRecords;

    constructor() {
        quotaPerDay = 100 ether;
    }
 
    function name() public pure override returns (string memory) {
        return "NEST";
    }

    function symbol() external pure override returns (string memory) {
        return "NEST";
    }

    function decimals() public pure override returns (uint8) {
        return uint8(18);
    }

    function remain(address target) external view returns (uint value) {
        value = quotaPerDay - _drawnRecords[(uint160(msg.sender) << 96) | (block.timestamp / 86400)];
    }

    function faucet() external {
        uint key = (uint160(msg.sender) << 96) | (block.timestamp / 86400);
        uint drawn = _drawnRecords[key];
        require(drawn < quotaPerDay, "NT:You have drawn today");
        uint remain = quotaPerDay - drawn;
        _mint(msg.sender, remain);
        _drawnRecords[key] = drawn + remain;
    }

    function mintTo(address to, uint value) external onlyGovernance {
        _mint(to, value);
    }
    
    function setQuotaPerDay(uint value) external onlyGovernance {
        quotaPerDay = value;
    }
}
