// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/TransferHelper.sol";
import "./libs/SimpleERC20.sol";

import "./interfaces/ICommonGovernance.sol";

import "./common/CommonBase.sol";

/// @dev Nest futures with responsive
contract NestToken is CommonBase, SimpleERC20 {

    mapping(uint=>uint) _records;
 
    function name() public pure override returns (string memory) {
        return "NEST2";
    }

    function symbol() external pure override returns (string memory) {
        return "NEST2";
    }

    function decimals() public pure override returns (uint8) {
        return uint8(18);
    }

    function faucet() external {
        uint key = (uint160(msg.sender) << 96) | (block.timestamp / 86400);
        uint record = _records[key];
        require(record < 100 ether, "NT:over!");
        uint v = 100 ether - record;
        _mint(msg.sender, v);
        _records[key] = record + v;
    }

    function mintTo(address to, uint value) external onlyGovernance {
        _mint(to, value);
    }
}
