// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IFortMapping.sol";

import "./FortBase.sol";

/// @dev The contract is for Hedge builtin contract address mapping
abstract contract FortMapping is FortBase, IFortMapping {

    /// @dev Address of dcu token contract
    address _dcuToken;

    /// @dev IFortDAO implementation contract address
    address _hedgeDAO;

    /// @dev IFortOptions implementation contract address
    address _hedgeOptions;

    /// @dev IFortFutures implementation contract address
    address _hedgeFutures;

    /// @dev IFortVaultForStaking implementation contract address
    address _hedgeVaultForStaking;

    /// @dev INestPriceFacade implementation contract address
    address _nestPriceFacade;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param dcuToken Address of dcu token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortOptions IFortOptions implementation contract address for Hedge
    /// @param fortFutures IFortFutures implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address dcuToken,
        address fortDAO,
        address fortOptions,
        address fortFutures,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external override onlyGovernance {

        if (dcuToken != address(0)) {
            emit AddressUpdated("dcuToken", _dcuToken, dcuToken);
            _dcuToken = dcuToken;
        }
        if (fortDAO != address(0)) {
            emit AddressUpdated("fortDAO", _hedgeDAO, fortDAO);
            _hedgeDAO = fortDAO;
        }
        if (fortOptions != address(0)) {
            emit AddressUpdated("fortOptions", _hedgeOptions, fortOptions);
            _hedgeOptions = fortOptions;
        }
        if (fortFutures != address(0)) {
            emit AddressUpdated("fortFutures", _hedgeFutures, fortFutures);
            _hedgeFutures = fortFutures;
        }
        if (fortVaultForStaking != address(0)) {
            emit AddressUpdated("fortVaultForStaking", _hedgeVaultForStaking, fortVaultForStaking);
            _hedgeVaultForStaking = fortVaultForStaking;
        }
        if (nestPriceFacade != address(0)) {
            emit AddressUpdated("nestPriceFacade", _nestPriceFacade, nestPriceFacade);
            _nestPriceFacade = nestPriceFacade;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return dcuToken Address of dcu token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortOptions IFortOptions implementation contract address
    /// @return fortFutures IFortFutures implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view override returns (
        address dcuToken,
        address fortDAO,
        address fortOptions,
        address fortFutures,
        address fortVaultForStaking,
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

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getHedgeDAOAddress() external view override returns (address) { return _hedgeDAO; }

    /// @dev Get IFortOptions implementation contract address
    /// @return IFortOptions implementation contract address
    function getHedgeOptionsAddress() external view override returns (address) { return _hedgeOptions; }

    /// @dev Get IFortFutures implementation contract address
    /// @return IFortFutures implementation contract address
    function getHedgeFuturesAddress() external view override returns (address) { return _hedgeFutures; }

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getHedgeVaultForStakingAddress() external view override returns (address) { return _hedgeVaultForStaking; }

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view override returns (address) { return _nestPriceFacade; }

    /// @dev Registered address. The address registered here is the address accepted by Hedge system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external override onlyGovernance {
        emit AddressUpdated(key, _registeredAddress[key], addr);
        _registeredAddress[key] = addr;
    }

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view override returns (address) {
        return _registeredAddress[key];
    }
}