// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Specific parameters for target chain
contract ChainParameter {

    // Block average time. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds
    uint constant BLOCK_TIME = 3;

    // Minimal exercise block period. 840000
    uint constant MIN_PERIOD = 840000;

    // Minimal exercise block period for NestLPGuarantee. 840000
    uint constant MIN_EXERCISE_BLOCK = 840000;
}
