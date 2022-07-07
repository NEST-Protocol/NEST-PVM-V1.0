// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity ^0.8.6;

// import "./interfaces/IFortVault.sol";

// import "./FortPRC.sol";

// /// @dev NestPRC
// contract NestPRC44 is FortPRCToken {

//     // Roll dice44 structure
//     struct Dice44 {
//         address owner;
//         uint32 n;
//         uint32 m;
//         uint32 openBlock;
//     }

//     // Roll dice44 information view
//     struct DiceView44 {
//         uint index;
//         address owner;
//         uint32 n;
//         uint32 m;
//         uint32 openBlock;
//         uint gained;
//     }

//     // The span from current block to hash block
//     uint constant OPEN_BLOCK_SPAN44 = 1;

//     // 4 decimals for M
//     uint constant M_BASE44 = 10000;

//     // 4 decimals for N
//     uint constant N_BASE44 = 10000;
    
//     // MAX M. [1.0000, 100.0000]
//     uint constant MAX_M44 = 100 * M_BASE44;
    
//     // MAX N, [0.0001, 1000.0000]
//     uint constant MAX_N44 = 1000 * N_BASE44;

//     // Roll dice44 array
//     Dice44[] _dices44;

//     /// @dev Find the dices44 of the target address (in reverse order)
//     /// @param start Find forward from the index corresponding to the given contract address 
//     /// (excluding the record corresponding to start)
//     /// @param count Maximum number of records returned
//     /// @param maxFindCount Find records at most
//     /// @param owner Target address
//     /// @return diceArray44 Matched dice44 array
//     function find44(
//         uint start, 
//         uint count, 
//         uint maxFindCount, 
//         address owner
//     ) external view returns (DiceView44[] memory diceArray44) {
//         diceArray44 = new DiceView44[](count);
//         // Calculate search region
//         Dice44[] storage dices44 = _dices44;
//         // Loop from start to end
//         uint end = 0;
//         // start is 0 means Loop from the last item
//         if (start == 0) {
//             start = dices44.length;
//         }
//         // start > maxFindCount, so end is not 0
//         if (start > maxFindCount) {
//             end = start - maxFindCount;
//         }
        
//         // Loop lookup to write qualified records to the buffer
//         for (uint index = 0; index < count && start > end;) {
//             Dice44 memory dice44 = dices44[--start];
//             if (dice44.owner == owner) {
//                 diceArray44[index++] = _toDiceView44(dice44, start);
//             }
//         }
//     }

//     /// @dev List dice44
//     /// @param offset Skip previous (offset) records
//     /// @param count Return (count) records
//     /// @param order Order. 0 reverse order, non-0 positive order
//     /// @return diceArray44 Matched dice44 array
//     function list44(
//         uint offset, 
//         uint count, 
//         uint order
//     ) external view returns (DiceView44[] memory diceArray44) {

//         // Load dices44
//         Dice44[] storage dices44 = _dices44;
//         // Create result array
//         diceArray44 = new DiceView44[](count);
//         uint length = dices44.length;
//         uint i = 0;

//         // Reverse order
//         if (order == 0) {
//             uint index = length - offset;
//             uint end = index > count ? index - count : 0;
//             while (index > end) {
//                 Dice44 memory gi = dices44[--index];
//                 diceArray44[i++] = _toDiceView44(gi, index);
//             }
//         } 
//         // Positive order
//         else {
//             uint index = offset;
//             uint end = index + count;
//             if (end > length) {
//                 end = length;
//             }
//             while (index < end) {
//                 diceArray44[i++] = _toDiceView44(dices44[index], index);
//                 ++index;
//             }
//         }
//     }

//     /// @dev Obtain the number of dices44 that have been opened
//     /// @return Number of dices44 opened
//     function getDiceCount44() external view returns (uint) {
//         return _dices44.length;
//     }

//     /// @dev start a roll dice44
//     /// @param n count of PRC
//     /// @param m times, 4 decimals
//     function roll44(uint n, uint m) external {
//         require(n > 0 && n <= MAX_N44  && m >= M_BASE44 && m <= MAX_M44, "PRC:n or m not valid");
//         _burn(msg.sender, n * 1 ether / N_BASE44);
//         _dices44.push(Dice44(msg.sender, uint32(n), uint32(m), uint32(block.number)));
//     }

//     /// @dev Claim gained DCU
//     /// @param index index of bet
//     function claim44(uint index) external {
//         Dice44 memory dice44 = _dices44[index];
//         uint gain = _gained44(dice44, index);
//         if (gain > 0) {
//             //DCU(DCU_TOKEN_ADDRESS).mint(dice44.owner, gain);
//             IFortVault(FORT_VAULT_ADDRESS).transferTo(dice44.owner, gain);
//         }

//         _dices44[index].n = uint32(0);
//     }

//     /// @dev Batch claim gained DCU
//     /// @param indices Indices of bets
//     function batchClaim44(uint[] calldata indices) external {
        
//         address owner = address(0);
//         uint gain = 0;

//         for (uint i = indices.length; i > 0;) {
//             uint index = indices[--i];
//             Dice44 memory dice44 = _dices44[index];
//             if (owner == address(0)) {
//                 owner = dice44.owner;
//             } else {
//                 require(owner == dice44.owner, "PRC:different owner");
//             }
//             gain += _gained44(dice44, index);
//             _dices44[index].n = uint32(0);
//         }

//         if (owner > address(0)) {
//             //DCU(DCU_TOKEN_ADDRESS).mint(owner, gain);
//             IFortVault(FORT_VAULT_ADDRESS).transferTo(owner, gain);
//         }
//     }

//     // Calculate gained number of DCU
//     function _gained44(Dice44 memory dice44, uint index) private view returns (uint gain) {
//         uint hashBlock = uint(dice44.openBlock) + OPEN_BLOCK_SPAN44;
//         require(block.number > hashBlock, "PRC:!hashBlock");
//         uint hashValue = uint(blockhash(hashBlock));
//         if (hashValue > 0) {
//             hashValue = uint(keccak256(abi.encodePacked(hashValue, index)));
//             if (hashValue % uint(dice44.m) < M_BASE44) {
//                 gain = uint(dice44.n) * uint(dice44.m) * 1 ether / M_BASE44 / N_BASE44;
//             }
//         }
//     }

//     // Convert Dice44 to DiceView44
//     function _toDiceView44(Dice44 memory dice44, uint index) private view returns (DiceView44 memory div) {
//         div = DiceView44(
//             index,
//             dice44.owner,
//             dice44.n,
//             dice44.m,
//             dice44.openBlock,
//             block.number > uint(dice44.openBlock) + OPEN_BLOCK_SPAN44 ? _gained44(dice44, index) : 0
//         );
//     }
// }
