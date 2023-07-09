// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "./libs/TransferHelper.sol";

import "./common/CommonBase.sol";

/// @dev This contract is used for batch transfers
contract Gatling is CommonBase {

    function strafe(address tokenAddress, address[] calldata targetAddresses, uint[] calldata amounts) external payable {
        if (tokenAddress == address(0)) {
            uint remain = msg.value;
            for (uint i = targetAddresses.length; i > 0; ) {
                uint amount = amounts[--i];
                remain      -= amount;

                payable(targetAddresses[i]).transfer(amount);
            }
            if (remain > 0) {
                payable(msg.sender).transfer(remain);
            }
        } else {
            uint total = 0;
            for (uint i = amounts.length; i > 0;) {
                total += amounts[--i];
            }
            TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), total);
            for (uint i = targetAddresses.length; i > 0;) {
                address targetAddress = targetAddresses[--i];
                TransferHelper.safeTransfer(tokenAddress, targetAddress, amounts[i]);
            }
        }
    }
}
