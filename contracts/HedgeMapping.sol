// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IHedgeMapping.sol";

import "./HedgeBase.sol";

/// @dev The contract is for Hedge builtin contract address mapping
abstract contract HedgeMapping is HedgeBase, IHedgeMapping {

    /// @dev Address of dcu token contract
    address _dcuToken;

    /// @dev IHedgeDAO implementation contract address
    address _hedgeDAO;

    /// @dev IHedgeOptions implementation contract address
    address _hedgeOptions;

    /// @dev IHedgeFutures implementation contract address
    address _hedgeFutures;

    /// @dev IHedgeVaultForStaking implementation contract address
    address _hedgeVaultForStaking;

    /// @dev INestPriceFacade implementation contract address
    address _nestPriceFacade;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param dcuToken Address of dcu token contract
    /// @param hedgeDAO IHedgeDAO implementation contract address
    /// @param hedgeOptions IHedgeOptions implementation contract address for Hedge
    /// @param hedgeFutures IHedgeFutures implementation contract address
    /// @param hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    ) external override onlyGovernance {

        if (dcuToken != address(0)) {
            _dcuToken = dcuToken;
        }
        if (hedgeDAO != address(0)) {
            _hedgeDAO = hedgeDAO;
        }
        if (hedgeOptions != address(0)) {
            _hedgeOptions = hedgeOptions;
        }
        if (hedgeFutures != address(0)) {
            _hedgeFutures = hedgeFutures;
        }
        if (hedgeVaultForStaking != address(0)) {
            _hedgeVaultForStaking = hedgeVaultForStaking;
        }
        if (nestPriceFacade != address(0)) {
            _nestPriceFacade = nestPriceFacade;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return dcuToken Address of dcu token contract
    /// @return hedgeDAO IHedgeDAO implementation contract address
    /// @return hedgeOptions IHedgeOptions implementation contract address
    /// @return hedgeFutures IHedgeFutures implementation contract address
    /// @return hedgeVaultForStaking IHedgeVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view override returns (
        address dcuToken,
        address hedgeDAO,
        address hedgeOptions,
        address hedgeFutures,
        address hedgeVaultForStaking,
        address nestPriceFacade
    ) {
        return (
            _dcuToken,
            _hedgeDAO,
            _hedgeOptions,
            _hedgeFutures,
            _hedgeVaultForStaking,
            _nestPriceFacade
        );
    }

    /// @dev Get address of dcu token contract
    /// @return Address of dcu token contract
    function getDCUTokenAddress() external view override returns (address) { return _dcuToken; }

    /// @dev Get IHedgeDAO implementation contract address
    /// @return IHedgeDAO implementation contract address
    function getHedgeDAOAddress() external view override returns (address) { return _hedgeDAO; }

    /// @dev Get IHedgeOptions implementation contract address
    /// @return IHedgeOptions implementation contract address
    function getHedgeOptionsAddress() external view override returns (address) { return _hedgeOptions; }

    /// @dev Get IHedgeFutures implementation contract address
    /// @return IHedgeFutures implementation contract address
    function getHedgeFuturesAddress() external view override returns (address) { return _hedgeFutures; }

    /// @dev Get IHedgeVaultForStaking implementation contract address
    /// @return IHedgeVaultForStaking implementation contract address
    function getHedgeVaultForStakingAddress() external view override returns (address) { return _hedgeVaultForStaking; }

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view override returns (address) { return _nestPriceFacade; }

    /// @dev Registered address. The address registered here is the address accepted by Hedge system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external override onlyGovernance {
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view override returns (address) {
        return _registeredAddress[key];
    }
}