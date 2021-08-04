// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INestPriceFacade.sol";

/// @dev 二元期权
contract FortToken is ERC20("Fort", "Fort") {

    address _owner;
    constructor() {
        _owner = msg.sender;
    }

    function mint(address to, uint amount) external {
        //require(msg.sender == _owner, "FortToken: not owner");
        _mint(to, amount);
    }

    function burn(address from, uint amount) external {
        //require(msg.sender == _owner, "FortToken: not owner");
        _burn(from, amount);
    }
}