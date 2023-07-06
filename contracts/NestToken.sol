// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/SimpleERC20.sol";

import "./common/CommonBase.sol";

/// @dev Nest Token for scroll test net
contract NestToken is CommonBase, SimpleERC20 {

    uint _quotaPerDay;

    mapping(uint=>uint) _drawnRecords;

    constructor() {
        _quotaPerDay = 100 ether;
    }
 
    function name() public pure override returns (string memory) {
        return "NEST_OLD";
    }

    function symbol() external pure override returns (string memory) {
        return "NEST_OLD";
    }

    function decimals() public pure override returns (uint8) {
        return uint8(18);
    }

    function remain(address target) external view returns (uint value) {
        value = _quotaPerDay - _drawnRecords[(uint160(target) << 96) | (block.timestamp / 86400)];
    }

    function faucet() external {
        uint key = (uint160(msg.sender) << 96) | (block.timestamp / 86400);
        uint drawn = _drawnRecords[key];
        require(drawn < _quotaPerDay, "NT:You have drawn today");
        uint remained = _quotaPerDay - drawn;
        _mint(msg.sender, remained);
        _drawnRecords[key] = drawn + remained;
    }

    function mintTo(address to, uint value) external onlyGovernance {
        _mint(to, value);
    }
    
    function setQuotaPerDay(uint value) external onlyGovernance {
        _quotaPerDay = value;
    }
}
