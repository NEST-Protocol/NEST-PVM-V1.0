// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/SimpleERC20.sol";

/// @dev New NEST Token for BSC
contract NestTokenNew is SimpleERC20 {

    constructor() {
        _mint(msg.sender, 10000000000 ether);
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
}
