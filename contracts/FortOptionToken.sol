// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INestPriceFacade.sol";

/// @dev 期权凭证
contract FortOptionToken is ERC20 {

    address immutable OWNER;
    address immutable TOKEN_ADDRESS;
    uint immutable PRICE;
    bool immutable ORIENTATION;
    uint immutable ENDBLOCK;

    constructor(
        string memory name, 
        string memory symbol, 
        address tokenAddress, 
        uint price,
        bool orientation,
        uint endblock
    ) ERC20(name, symbol) {
        
        OWNER = msg.sender;
        TOKEN_ADDRESS = tokenAddress;
        PRICE = price;
        ORIENTATION = orientation;
        ENDBLOCK = endblock;
    }

    modifier onlyOwner {
        require(msg.sender == OWNER, "FortOptionToken:not owner");
        _;
    }
    
    /// @dev 获取期权信息
    /// @return tokenAddress 目标代币地址
    /// @return price 行权价格
    /// @return orientation 期权方向
    /// @return endblock 行权区块号
    function getOptionInfo() external view returns (
        address tokenAddress, 
        uint price,
        bool orientation,
        uint endblock
    ) {
        return (TOKEN_ADDRESS, PRICE, ORIENTATION, ENDBLOCK);
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