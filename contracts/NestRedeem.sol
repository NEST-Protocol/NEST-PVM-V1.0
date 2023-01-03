// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/INestGovernance.sol";

import "./NestBase.sol";

/// @dev Nest redeeming
contract NestRedeem is NestBase {
    
    uint immutable EXCHANGE_RATIO;

    address immutable OLD_TOKEN;
    address immutable NEW_TOKEN;

    constructor(address oldToken, address newToken, uint exchangeRatio) {
        OLD_TOKEN = oldToken;
        NEW_TOKEN = newToken;
        EXCHANGE_RATIO = exchangeRatio;
    }

    /// @dev Redeem old token for new token
    /// @param oldTokenAmount Amount of old token
    function redeem(uint oldTokenAmount) external {
        TransferHelper.safeTransferFrom(OLD_TOKEN, msg.sender, address(this), oldTokenAmount);
        TransferHelper.safeTransfer(NEW_TOKEN, msg.sender, oldTokenAmount * EXCHANGE_RATIO / 1 ether);
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// The funds of in BuybackPool is offered by DAO, after buyback ended, transfer tokens to DAO
    function migrate() external onlyGovernance {
        address to = INestGovernance(_governance).getNestLedgerAddress();
        TransferHelper.safeTransfer(OLD_TOKEN, to, IERC20(OLD_TOKEN).balanceOf(address(this)));
        TransferHelper.safeTransfer(NEW_TOKEN, to, IERC20(NEW_TOKEN).balanceOf(address(this)));
    }
}
