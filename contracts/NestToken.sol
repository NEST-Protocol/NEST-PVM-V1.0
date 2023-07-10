// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./common/CommonBase.sol";

/// @dev This is the only valid NEST token issued by the NEST project team on BSC
contract NestToken is ERC20, CommonBase {
    
    constructor() ERC20("NEST", "NEST") { }

    function mintTo(address to, uint amount) external onlyGovernance {
        _mint(to, amount);
    }

    function burnFrom(address from, uint amount) external onlyGovernance {
        _burn(from, amount);
    }
}
