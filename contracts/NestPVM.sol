// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/TransferHelper.sol";
import "./libs/PVM.sol";

import "./interfaces/INestPVMFunction.sol";
import "./interfaces/INestFutures.sol";
import "./interfaces/INestVault.sol";

import "./custom/ChainParameter.sol";
import "./custom/NestFrequentlyUsed.sol";
import "./custom/NestPriceAdapter.sol";

/// @dev Futures
contract NestPVM is ChainParameter, NestFrequentlyUsed, NestPriceAdapter {

    mapping(uint=>uint) _functionMap;

}
