// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Nest Vault
interface INestPVMFunction {

    /// @dev Calculate value
    /// @dev byte array of arguments encoded by abi.encode()
    function calculate(bytes memory abiArgs) external returns (uint);
}
