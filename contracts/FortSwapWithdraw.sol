// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortSwap.sol";

import "./custom/HedgeFrequentlyUsed.sol";

/// @dev Swap dcu with token
contract FortSwapWithdraw is HedgeFrequentlyUsed {

    address constant FORT_DAO_ADDRESS = address(0);

    // Target token address
    address constant TOKEN_ADDRESS = 0x55d398326f99059fF775485246999027B3197955;

    // K value, according to schedule, sell out nest from HedgeSwap pool on ethereum mainnet,
    // Exchange to usdt, and cross to BSC smart chain. Excluding exchange and cross chain consumption, 
    // a total of 952297.70usdt was obtained, address: 0x2bE88070a330Ef106E0ef77A45bd1F583BFcCf4E.
    // 77027.78usdt transferred to 0xc5229c9e1cbe1888b23015d283413a9c5e353ac7 as project expenditure.
    // 100000.00usdt transferred to the DAO address 0x9221295CE0E0D2E505CbeA635fa6730961FB5dFa for project funds.
    // The remaining 775269.92usdt transfer to the new usdt/dcu swap pool.
    // According to the price when nest/dcu swap pool stops, 1dcu=0.3289221986usdt,
    // The calculated number of dcu is 2357000.92.
    uint constant K = 775269925761307568974296 * 2357000923200406848351572;

    constructor() {
    }

    function withdraw() external onlyGovernance {
        uint balanceUSDT = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
        uint balanceDCU = IERC20(DCU_TOKEN_ADDRESS).balanceOf(address(this));

        uint tUSDT = balanceUSDT - 200000 ether;
        uint tDCU = balanceDCU - balanceDCU * 200000 ether / balanceUSDT;

        IERC20(TOKEN_ADDRESS).transfer(FORT_DAO_ADDRESS, tUSDT);
        IERC20(DCU_TOKEN_ADDRESS).transfer(FORT_DAO_ADDRESS, tDCU);
    }
}
