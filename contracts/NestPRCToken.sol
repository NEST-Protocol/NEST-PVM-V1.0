// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/SimpleERC20.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Guarantee
contract NestPRCToken is NestFrequentlyUsed, SimpleERC20 {

    /// @dev Mining permission flag change event
    /// @param account Target address
    /// @param oldFlag Old flag
    /// @param newFlag New flag
    event MinterChanged(address account, uint oldFlag, uint newFlag);

    // Flags for account
    mapping(address=>uint) _flags;

    constructor() {
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public pure virtual override returns (string memory) {
        return "Probability Coin";
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public pure virtual override returns (string memory) {
        return "PRC";
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure virtual override returns (uint8) {
        return 18;
    }

    /// @dev Set mining permission flag
    /// @param account Target address
    /// @param flag Mining permission flag
    function setMinter(address account, uint flag) external onlyGovernance {
        emit MinterChanged(account, _flags[account], flag);
        _flags[account] = flag;
    }

    /// @dev Check mining permission flag
    /// @param account Target address
    /// @return flag Mining permission flag
    function checkMinter(address account) external view returns (uint) {
        return _flags[account];
    }

    /// @dev Mint NestRPC
    /// @param to Target address
    /// @param value Mint amount
    function mint(address to, uint value) external {
        require(_flags[msg.sender] & 0x01 == 0x01, "NestRPC:!mint");
        _mint(to, value);
    }

    /// @dev Burn NestRPC
    /// @param from Target address
    /// @param value Burn amount
    function burn(address from, uint value) external {
        require(_flags[msg.sender] & 0x02 == 0x02, "NestRPC:!burn");
        _burn(from, value);
    }
}
