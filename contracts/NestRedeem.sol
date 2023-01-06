// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

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

    /// @dev Migrate token to NestLedger
    /// @param tokenAddress Address of target token
    /// @param value Value of target token
    function migrate(address tokenAddress, uint value) external onlyGovernance {
        TransferHelper.safeTransfer(tokenAddress, INestGovernance(_governance).getNestLedgerAddress(), value);
    }
}
