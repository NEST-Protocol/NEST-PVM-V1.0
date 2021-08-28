// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INestPriceFacade.sol";

// TODO: 代币名称
/// @dev 期权凭证
contract FortOptionToken is ERC20 {

    address immutable TOKEN_ADDRESS;
    address immutable OWNER;

    uint88 _endblock;
    // TODO: orientation 没有作用
    bool _orientation;
    uint _price;

    constructor(
        string memory name, 
        string memory symbol, 
        address tokenAddress, 
        uint88 endblock, 
        bool orientation, 
        uint price
    ) ERC20(name, symbol) {
        
        OWNER = msg.sender;
        TOKEN_ADDRESS = tokenAddress;
        _endblock = endblock;
        _orientation = orientation;
        _price = price;
    }

    modifier onlyOwner {
        require(msg.sender == OWNER, "FortOptionToken:not owner");
        _;
    }
    
    /// @dev 获取期权信息
    /// @return tokenAddress 目标代币地址
    /// @return endblock 行权区块号
    /// @return orientation 期权方向
    /// @return price 行权价格
    function getOptionInfo() external view returns (
        address tokenAddress, 
        uint endblock, 
        bool orientation, 
        uint price
    ) {
        return (TOKEN_ADDRESS, uint(_endblock), _orientation, _price);
    }

    /// @dev 铸币
    /// @param to 接收地址
    /// @param value 铸币数量
    function mint(address to, uint value) external onlyOwner {
        _mint(to, value);
    }

    /// @dev 销毁
    /// @param from 目标地址
    /// @param value 销毁数量
    function burn(address from, uint value) external onlyOwner {
        _burn(from, value);
    }
}