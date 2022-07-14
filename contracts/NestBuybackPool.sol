// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/INestGovernance.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev After the merger, DCU will no longer be used, and the circulated DCU can be swap to NEST through this contract
contract NestBuybackPool is NestFrequentlyUsed {

    // Indicates how many NEST can be exchanged for one DCU
    // The specific value will be determined before deployment
    uint constant EXCHANGE_RATIO = 3.3 ether;

    // Address of DCU token
    // address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

    // TODO: Use constant version
    // Address of DCU token
    address DCU_TOKEN_ADDRESS;
    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        DCU_TOKEN_ADDRESS = INestGovernance(newGovernance).checkAddress("nest.app.dcu");
    }

    constructor() {
    }

    /// @dev Swap DCU to NEST
    /// @param dcuAmount Amount of DCU
    function swap(uint dcuAmount) external {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, msg.sender, dcuAmount * EXCHANGE_RATIO / 1 ether);
    }

    /// @dev Migrate funds from current contract to NestLedger
    /// The funds of in BuybackPool is offered by DAO, after buyback ended, transfer tokens to DAO
    function migrate() external onlyGovernance {
        address to = INestGovernance(_governance).getNestLedgerAddress();
        TransferHelper.safeTransfer(DCU_TOKEN_ADDRESS, to, IERC20(DCU_TOKEN_ADDRESS).balanceOf(address(this)));
        TransferHelper.safeTransfer(NEST_TOKEN_ADDRESS, to, IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this)));
    }
}
