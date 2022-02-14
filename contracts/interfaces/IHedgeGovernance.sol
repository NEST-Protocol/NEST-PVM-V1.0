// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./IHedgeMapping.sol";

/// @dev This interface defines the governance methods
interface IHedgeGovernance is IHedgeMapping {

    /// @dev Governance flag changed event
    /// @param addr Target address
    /// @param oldFlag Old governance flag
    /// @param newFlag New governance flag
    event FlagChanged(address addr, uint oldFlag, uint newFlag);

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}