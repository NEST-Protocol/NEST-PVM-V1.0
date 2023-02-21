// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";

import "./custom/NestFrequentlyUsed.sol";

/// @dev Futures proxy
contract NestStakingTrade is NestFrequentlyUsed {

    address immutable OWNER;
    address immutable TARGET_TOKEN_ADDRESS;
    address immutable PAY_TOKEN_ADDRESS;
    uint immutable TRADE_RATIO;
    uint immutable STAKING_BLOCKS;

    struct Order {
        address owner;
        uint96 tradeBlock;
        uint amount;
    }

    Order[] _orders;

    constructor(
        address targetTokenAddress,
        address payTokenAddress,
        uint tradeRatio,
        uint stakingBlocks
    ) {
        OWNER = msg.sender;
        TARGET_TOKEN_ADDRESS = targetTokenAddress;
        PAY_TOKEN_ADDRESS = payTokenAddress;
        TRADE_RATIO = tradeRatio;
        STAKING_BLOCKS = stakingBlocks;
    }
    
    function buy(uint amount) external payable {
        _orders.push(Order(
            msg.sender,
            uint96(block.number),
            amount
        ));

        if (PAY_TOKEN_ADDRESS == address(0)) {
            require(msg.value == amount * TRADE_RATIO / 1 ether, "NST:value error");
        } else {
            TransferHelper.safeTransferFrom(
                PAY_TOKEN_ADDRESS,
                msg.sender,
                address(this),
                amount * TRADE_RATIO / 1 ether
            );
        }
    }
    
    function withdraw(uint index) external {
        Order memory order = _orders[index];
        require(block.number > order.tradeBlock + STAKING_BLOCKS, "NST:staking");
        TransferHelper.safeTransfer(TARGET_TOKEN_ADDRESS, order.owner, order.amount);
        _orders[index].amount = 0;
    }

    /// @dev Migrate token to NestLedger
    /// @param tokenAddress Address of target token
    /// @param value Value of target token
    function migrate(address tokenAddress, uint value) external {
        require(msg.sender == OWNER, "NST:not owner");
        if (tokenAddress == address(0)) {
            payable(OWNER).transfer(value);
        } else {
            TransferHelper.safeTransfer(tokenAddress, OWNER, value);
        }
    }

    receive() external payable {
    }
}
