// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev This is the only valid NEST token issued by the NEST project team on BSC
contract ArithFi is ERC20 {
    
    constructor() ERC20("ArithFi", "ATF") {
        _mint(msg.sender, 1000000000 ether);
    }

}
