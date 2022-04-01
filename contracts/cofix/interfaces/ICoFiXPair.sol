// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ICoFiXPool.sol";

/// @dev Binary pool: eth/token
interface ICoFiXPair is ICoFiXPool {

    /// @dev Swap for token event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountTokenOut The real amount of token transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForToken(uint amountIn, address to, uint amountTokenOut, uint mined);

    /// @dev Swap for eth event
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param amountETHOut The real amount of eth transferred out of pool
    /// @param mined The amount of CoFi which will be mind by this trade
    event SwapForETH(uint amountIn, address to, uint amountETHOut, uint mined);

    /// @dev Set configuration
    /// @param theta Trade fee rate, ten thousand points system. 20
    /// @param impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    /// @param nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function setConfig(uint16 theta, uint96 impactCostVOL, uint96 nt) external;

    /// @dev Get configuration
    /// @return theta Trade fee rate, ten thousand points system. 20
    /// @return impactCostVOL 将impactCostVOL参数的意义做出调整，表示冲击成本倍数
    /// @return nt Each unit token (in the case of binary pools, eth) is used for the standard ore output, 1e18 based
    function getConfig() external view returns (uint16 theta, uint96 impactCostVOL, uint96 nt);

    /// @dev Get initial asset ratio
    /// @return initToken0Amount Initial asset ratio - eth
    /// @return initToken1Amount Initial asset ratio - token
    function getInitialAssetRatio() external view returns (uint initToken0Amount, uint initToken1Amount);

    /// @dev Estimate mining amount
    /// @param newBalance0 New balance of eth
    /// @param newBalance1 New balance of token
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return mined The amount of CoFi which will be mind by this trade
    function estimate(
        uint newBalance0, 
        uint newBalance1, 
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint mined);
    
    /// @dev Settle trade fee to DAO
    function settle() external;

    /// @dev Get eth balance of this pool
    /// @return eth balance of this pool
    function ethBalance() external view returns (uint);

    /// @dev Get total trade fee which not settled
    function totalFee() external view returns (uint);
    
    /// @dev Get net worth
    /// @param ethAmount Oracle price - eth amount
    /// @param tokenAmount Oracle price - token amount
    /// @return navps Net worth
    function getNAVPerShare(
        uint ethAmount, 
        uint tokenAmount
    ) external view returns (uint navps);

    /// @dev Calculate the impact cost of buy in eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForBuyInETH(uint vol) external view returns (uint impactCost);

    /// @dev Calculate the impact cost of sell out eth
    /// @param vol Trade amount in eth
    /// @return impactCost Impact cost
    function impactCostForSellOutETH(uint vol) external view returns (uint impactCost);
}