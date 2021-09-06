// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// import "../libs/ERC20_LIB.sol";
// import "../libs/StringHelper.sol";

// import "../FortLeverToken.sol";

// import "hardhat/console.sol";

// contract TestCase {

//     address _fortLeverToken;

//     function create() external {
        
//         _fortLeverToken = address(new FortLeverToken(
//             "FLT001",
//             address(1),
//             address(2), 
//             5, 
//             true
//         ));

//         string memory n = getName();
//         console.log("name:", n);

//         string memory s = getSymbol();
        
//         console.log("symbol:", s);
//     }

//     function getSymbol() public returns (string memory ) {
//         try ERC20(_fortLeverToken).symbol() returns (string memory symbol) {
//             return symbol;
//         }
//         catch Error(string memory m) {
//             return "EM";
//         } catch (bytes memory b) {
//             return "EB";
//         }
//     }

//     function getName() public returns (string memory ) {
//         try ERC20(_fortLeverToken).name() returns (string memory name) {
//             return name;
//         }
//         catch Error(string memory m) {
//             return "EM";
//         } catch (bytes memory b) {
//             return "EB";
//         }
//     }
// }
