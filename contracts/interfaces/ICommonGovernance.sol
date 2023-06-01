// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface ICommonGovernance {

    function setAdministrator(address target, uint flag) external;

    function checkAdministrator(address target) external view returns (uint);

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);

    /// @dev Execute transaction from NestGovernance
    /// @param target Target address
    /// @param data Calldata
    /// @return success Return data in bytes
    function execute(address target, bytes calldata data) external payable returns (bool success);
}