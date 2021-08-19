// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IFortMapping.sol";

import "./FortBase.sol";

/// @dev The contract is for Fort builtin contract address mapping
abstract contract FortMapping is FortBase, IFortMapping {

    /// @dev Address of fort token contract
    address _fortToken;

    /// @dev IFortDAO implementation contract address
    address _fortDAO;

    /// @dev IFortEuropeanOption implementation contract address for Fort
    address _fortEuropeanOption;

    /// @dev IFortLever implementation contract address
    address _fortLever;

    /// @dev IFortVaultForStaking implementation contract address
    address _fortVaultForStaking;

    /// @dev INestPriceFacade implementation contract address
    address _nestPriceFacade;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param fortToken Address of fort token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @param fortLever IFortLever implementation contract address
    /// @param fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @param nestPriceFacade INestPriceFacade implementation contract address
    function setBuiltinAddress(
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) external override onlyGovernance {

        if (fortToken != address(0)) {
            _fortToken = fortToken;
        }
        if (fortDAO != address(0)) {
            _fortDAO = fortDAO;
        }
        if (fortEuropeanOption != address(0)) {
            _fortEuropeanOption = fortEuropeanOption;
        }
        if (fortLever != address(0)) {
            _fortLever = fortLever;
        }
        if (fortVaultForStaking != address(0)) {
            _fortVaultForStaking = fortVaultForStaking;
        }
        if (nestPriceFacade != address(0)) {
            _nestPriceFacade = nestPriceFacade;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return fortToken Address of fort token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortEuropeanOption IFortEuropeanOption implementation contract address for Fort
    /// @return fortLever IFortLever implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view override returns (
        address fortToken,
        address fortDAO,
        address fortEuropeanOption,
        address fortLever,
        address fortVaultForStaking,
        address nestPriceFacade
    ) {
        return (
            _fortToken,
            _fortDAO,
            _fortEuropeanOption,
            _fortLever,
            _fortVaultForStaking,
            _nestPriceFacade
        );
    }

    /// @dev Get address of fort token contract
    /// @return Address of fort token contract
    function getFortTokenAddress() external view override returns (address) { return _fortToken; }

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view override returns (address) { return _fortDAO; }

    /// @dev Get IFortEuropeanOption implementation contract address for Fort
    /// @return IFortEuropeanOption implementation contract address for Fort
    function getFortEuropeanOptionAddress() external view override returns (address) { return _fortEuropeanOption; }

    /// @dev Get IFortLever implementation contract address
    /// @return IFortLever implementation contract address
    function getFortLeverAddress() external view override returns (address) { return _fortLever; }

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view override returns (address) { return _fortVaultForStaking; }

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view override returns (address) { return _nestPriceFacade; }

    /// @dev Registered address. The address registered here is the address accepted by Fort system
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