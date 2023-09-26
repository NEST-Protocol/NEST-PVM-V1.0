// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev This is the only valid NEST token issued by the NEST project team on ETH&BSC
contract ArithFi is ERC20 {
    
    constructor() ERC20("ArithFi", "ATF") {
        // On ETH
        _mint(msg.sender, 1000000000 ether);

        // On BSC
        //_mint(msg.sender, 300000000 ether);
    }

}
