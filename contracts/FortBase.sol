// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IFortDAO.sol";
import "./interfaces/IFortGovernance.sol";

// Router contract to interact with each FortPair, no owner or governance
/// @dev Base contract of Fort
contract FortBase {

    // Address of CoFiToken contract
    address constant FORT_TOKEN_ADDRESS = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;

    // Address of CoFiNode contract
    //address constant CNODE_TOKEN_ADDRESS = 0x558201DC4741efc11031Cdc3BC1bC728C23bF512;

    // Genesis block number of CoFi
    // CoFiToken contract is created at block height 11040156. However, because the mining algorithm of Fort1.0
    // is different from that at present, a new mining algorithm is adopted from Fort2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the CoFi begins to decay. According to the circulation when CoFi2.0 is online, the new mining
    // algorithm is used to deduce and convert the CoFi, and the new algorithm is used to mine the Fort2.1
    // on-line flow, the actual block is 11040688
    uint constant FORT_GENESIS_BLOCK = 0;

    /// @dev IFortGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IFortGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "Fort:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IFortGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IFortGovernance(governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to FortDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = IFortGovernance(_governance).getFortDAOAddress();
        if (tokenAddress == address(0)) {
            IFortDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IFortGovernance(_governance).checkGovernance(msg.sender, 0), "Fort:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "Fort:!contract");
        _;
    }
}
