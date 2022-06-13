// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for Hedge builtin contract address mapping
interface IFortMapping {

    /// @dev Address updated event
    /// @param name Address name
    /// @param oldAddress Old address
    /// @param newAddress New address
    event AddressUpdated(string name, address oldAddress, address newAddress);

    /// @dev Set the built-in contract address of the system
    /// @param dcuToken Address of dcu token contract
    /// @param fortDAO IFortDAO implementation contract address
    /// @param fortOptions IFortOptions implementation contract address
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
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return dcuToken Address of dcu token contract
    /// @return fortDAO IFortDAO implementation contract address
    /// @return fortOptions IFortOptions implementation contract address
    /// @return fortFutures IFortFutures implementation contract address
    /// @return fortVaultForStaking IFortVaultForStaking implementation contract address
    /// @return nestPriceFacade INestPriceFacade implementation contract address
    function getBuiltinAddress() external view returns (
        address dcuToken,
        address fortDAO,
        address fortOptions,
        address fortFutures,
        address fortVaultForStaking,
        address nestPriceFacade
    );

    /// @dev Get address of dcu token contract
    /// @return Address of dcu token contract
    function getDCUTokenAddress() external view returns (address);

    /// @dev Get IFortDAO implementation contract address
    /// @return IFortDAO implementation contract address
    function getHedgeDAOAddress() external view returns (address);

    /// @dev Get IFortOptions implementation contract address
    /// @return IFortOptions implementation contract address
    function getHedgeOptionsAddress() external view returns (address);

    /// @dev Get IFortFutures implementation contract address
    /// @return IFortFutures implementation contract address
    function getHedgeFuturesAddress() external view returns (address);

    /// @dev Get IFortVaultForStaking implementation contract address
    /// @return IFortVaultForStaking implementation contract address
    function getHedgeVaultForStakingAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacade() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by Hedge system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}