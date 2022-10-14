// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Specific parameters for target chain
contract ChainParameter {
    
    // // ETH:
    // // Block average time in milliseconds. ethereum 12.09 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 12090;
    // // Minimal exercise block period. 200000
    // uint constant MIN_PERIOD = 200000;
    // // Minimal exercise block period for NestLPGuarantee. 200000
    // uint constant MIN_EXERCISE_BLOCK = 200000;

    // BSC:
    // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    uint constant BLOCK_TIME = 3000;
    // Minimal exercise block period. 840000
    uint constant MIN_PERIOD = 840000;
    // Minimal exercise block period for NestLPGuarantee. 840000
    uint constant MIN_EXERCISE_BLOCK = 840000;

    // // Polygon:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 2200;
    // // Minimal exercise block period. 1200000
    // uint constant MIN_PERIOD = 1200000;
    // // Minimal exercise block period for NestLPGuarantee. 1200000
    // uint constant MIN_EXERCISE_BLOCK = 1200000;

    // // KCC:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 3000;
    // // Minimal exercise block period. 840000
    // uint constant MIN_PERIOD = 840000;
    // // Minimal exercise block period for NestLPGuarantee. 840000
    // uint constant MIN_EXERCISE_BLOCK = 840000;
}
