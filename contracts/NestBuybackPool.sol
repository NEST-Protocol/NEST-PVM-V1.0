// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/INestGovernance.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev After the merger, DCU will no longer be used, and the circulated DCU can be swap to NEST through this contract
contract NestBuybackPool is NestFrequentlyUsed {
    
    // [Announcement] Exchange rate for the merger of the NEST protocol and FORT protocol
    // After a vote from July 8th to July 14th, 2022, the NEST community approved the NEST and FORT merger plan. 
    // According to the voting proposal, besides the investors of FORT in the early stage, the consideration for 
    // the merger of NEST and FORT is the ratio of the 7-day average USDT prices of the two tokens.

    // This announcement explains the specific calculation method of the 7-day average price as follows:
    //     Calculate the daily average price* for each day from July 8th to July 14th, 2022
    //     Calculate the arithmetic average of the daily average prices obtained in 1) as the 7-day average price

    // *Note: the daily average price is the arithmetic average of all prices for the day. Specifically, all prices 
    // for the day for DCU include the prices corresponding to all transactions that occur in the FORT official DCU 
    // swap of the day. All prices for the day for NEST are all quotation prices for the day from the NEST oracle on 
    // BNB chain.

    // Based on the above method and data from July 8th to July 14th, 2022, the 7-day average prices for DCU and NEST
    // are equal to 0.253139024 USDT and 0.032586735 USDT, respectively. Thus the exchange rate for the merger of the 
    // NEST protocol and FORT protocol is 1 DCU = 7.768161615 NEST

    // NEST DAO July 15th, 2022
    
    // Indicates how many NEST can be exchanged for one DCU
    // The specific value will be determined before deployment
    uint constant EXCHANGE_RATIO = 7.768161615 ether;

    // Address of DCU token, it is the same on ETH, BSC, Polygon and KCC
    address constant DCU_TOKEN_ADDRESS = 0xf56c6eCE0C0d6Fbb9A53282C0DF71dBFaFA933eF;

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
