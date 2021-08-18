// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interfaces/IFortMapping.sol";

import "./FortBase.sol";

/// @dev The contract is for Fort builtin contract address mapping
abstract contract FortMapping is FortBase, IFortMapping {

    /// @dev Address of CoFi token contract
    address _cofiToken;

    /// @dev Address of CoFi Node contract
    address _cofiNode;

    /// @dev IFortDAO implementation contract address
    address _cofixDAO;

    /// @dev IFortRouter implementation contract address for Fort
    address _cofixRouter;

    /// @dev IFortController implementation contract address
    address _cofixController;

    /// @dev IFortVaultForStaking implementation contract address
    address _cofixVaultForStaking;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param cofiToken Address of CoFi token contract
    /// @param cofiNode Address of CoFi Node contract
    /// @param cofixDAO IFortDAO implementation contract address
    /// @param cofixRouter IFortRouter implementation contract address for Fort
    /// @param cofixController IFortController implementation contract address
    /// @param cofixVaultForStaking IFortVaultForStaking implementation contract address
    function setBuiltinAddress(
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) external override onlyGovernance {

        if (cofiToken != address(0)) {
            _cofiToken = cofiToken;
        }
        if (cofiNode != address(0)) {
            _cofiNode = cofiNode;
        }
        if (cofixDAO != address(0)) {
            _cofixDAO = cofixDAO;
        }
        if (cofixRouter != address(0)) {
            _cofixRouter = cofixRouter;
        }
        if (cofixController != address(0)) {
            _cofixController = cofixController;
        }
        if (cofixVaultForStaking != address(0)) {
            _cofixVaultForStaking = cofixVaultForStaking;
        }
    }

    /// @dev Get the built-in contract address of the system
    /// @return cofiToken Address of CoFi token contract
    /// @return cofiNode Address of CoFi Node contract
    /// @return cofixDAO IFortDAO implementation contract address
    /// @return cofixRouter IFortRouter implementation contract address for Fort
    /// @return cofixController IFortController implementation contract address
    function getBuiltinAddress() external view override returns (
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) {
        return (
            _cofiToken,
            _cofiNode,
            _cofixDAO,
            _cofixRouter,
            _cofixController,
            _cofixVaultForStaking
        );
    }

    /// @dev Get address of CoFi token contract
    /// @return Address of CoFi Node token contract
    function getCoFiTokenAddress() external view override returns (address) { return _cofiToken; }

    /// @dev Get address of CoFi Node contract
    /// @return Address of CoFi Node contract
    function getCoFiNodeAddress() external view override returns (address) { return _cofiNode; }

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getFortDAOAddress() external view override returns (address) { return _cofixDAO; }

    /// @dev Get IFortRouter implementation contract address for Fort
    /// @return IFortRouter implementation contract address for Fort
    function getFortRouterAddress() external view override returns (address) { return _cofixRouter; }

    /// @dev Get IFortController implementation contract address
    /// @return IFortController implementation contract address
    function getFortControllerAddress() external view override returns (address) { return _cofixController; }

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getFortVaultForStakingAddress() external view override returns (address) { return _cofixVaultForStaking; }

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