// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ICoFiXMapping.sol";

import "./CoFiXBase.sol";

/// @dev The contract is for CoFiX builtin contract address mapping
abstract contract CoFiXMapping is CoFiXBase, ICoFiXMapping {

    /// @dev Address of CoFi token contract
    address _cofiToken;

    /// @dev Address of CoFi Node contract
    address _cofiNode;

    /// @dev ICoFiXDAO implementation contract address
    address _cofixDAO;

    /// @dev ICoFiXRouter implementation contract address for CoFiX
    address _cofixRouter;

    /// @dev ICoFiXController implementation contract address
    address _cofixController;

    /// @dev ICoFiXVaultForStaking implementation contract address
    address _cofixVaultForStaking;

    /// @dev Address registered in the system
    mapping(string=>address) _registeredAddress;

    /// @dev Set the built-in contract address of the system
    /// @param cofiToken Address of CoFi token contract
    /// @param cofiNode Address of CoFi Node contract
    /// @param cofixDAO ICoFiXDAO implementation contract address
    /// @param cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @param cofixController ICoFiXController implementation contract address
    /// @param cofixVaultForStaking ICoFiXVaultForStaking implementation contract address
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
    /// @return cofixDAO ICoFiXDAO implementation contract address
    /// @return cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @return cofixController ICoFiXController implementation contract address
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
    /// @return Address of CoFi token contract
    function getCoFiTokenAddress() external view override returns (address) { return _cofiToken; }

    /// @dev Get address of CoFi Node contract
    /// @return Address of CoFi Node contract
    function getCoFiNodeAddress() external view override returns (address) { return _cofiNode; }

    /// @dev Get ICoFiXDAO implementation contract address
    /// @return ICoFiXDAO implementation contract address
    function getCoFiXDAOAddress() external view override returns (address) { return _cofixDAO; }

    /// @dev Get ICoFiXRouter implementation contract address for CoFiX
    /// @return ICoFiXRouter implementation contract address for CoFiX
    function getCoFiXRouterAddress() external view override returns (address) { return _cofixRouter; }

    /// @dev Get ICoFiXController implementation contract address
    /// @return ICoFiXController implementation contract address
    function getCoFiXControllerAddress() external view override returns (address) { return _cofixController; }

    /// @dev Get ICoFiXVaultForStaking implementation contract address
    /// @return ICoFiXVaultForStaking implementation contract address
    function getCoFiXVaultForStakingAddress() external view override returns (address) { return _cofixVaultForStaking; }

    /// @dev Registered address. The address registered here is the address accepted by CoFiX system
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