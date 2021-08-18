// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INestPriceFacade.sol";

/// @dev 期权凭证
contract FortOptionToken is ERC20("", "") {

    address immutable _tokenAddress;
    uint88 _endblock;
    bool _orientation;
    uint _price;

    address _owner;

    constructor(address tokenAddress, uint88 endblock, bool orientation, uint price) {
        _tokenAddress = tokenAddress;
        _endblock = endblock;
        _orientation = orientation;
        _price = price;

        _owner = msg.sender;
    }

    function getOptionInfo() external view returns (
        address tokenAddress, 
        uint endblock, 
        bool orientation, 
        uint price
    ) {
        return (_tokenAddress, uint(_endblock), _orientation, _price);
    }

    function mint(address to, uint amount) external {
        require(msg.sender == _owner, "FortOptionToken: not owner");
        _mint(to, amount);
    }

    function burn(address from, uint amount) external {
        require(msg.sender == _owner, "FortOptionToken: not owner");
        _burn(from, amount);
    }
}