// // SPDX-License-Identifier: GPL-3.0-or-later

// pragma solidity ^0.8.6;

// import "./libs/TransferHelper.sol";

// import "./interfaces/IFortFutures.sol";
// import "./interfaces/IFortVault.sol";

// import "./custom/ChainParameter.sol";
// import "./custom/FortFrequentlyUsed.sol";
// import "./custom/FortPriceAdapter.sol";

// /// @dev Futures
// contract NestFutures is ChainParameter, FortFrequentlyUsed, FortPriceAdapter, IFortFutures {

//     /// @dev Account information
//     struct Account {
//         // Amount of margin
//         uint128 balance;
//         // Base price
//         uint64 basePrice;
//         // Base block
//         uint32 baseBlock;
//     }

//     /// @dev Future information
//     struct FutureInfo {
//         // Target token address
//         address tokenAddress; 
//         // Lever of future
//         uint32 lever;
//         // true: call, false: put
//         bool orientation;

//         // Token index in _tokenConfigs
//         uint16 tokenIndex;
        
//         // Account mapping
//         mapping(address=>Account) accounts;
//     }

//     // Minimum balance quantity. If the balance is less than this value, it will be liquidated
//     uint constant MIN_VALUE = 10 ether;

//     // Mapping from composite key to future index
//     mapping(uint=>uint) _futureMapping;

//     // Future array, element of 0 is place holder
//     FutureInfo[] _futures;

//     // token to index mapping, address=>tokenConfigIndex + 1
//     mapping(address=>uint) _tokenMapping;

//     // Token configs
//     TokenConfig[] _tokenConfigs;

//     constructor() {
//     }

//     /// @dev To support open-zeppelin/upgrades
//     /// @param governance IFortGovernance implementation contract address
//     function initialize(address governance) public override {
//         super.initialize(governance);
//         _futures.push();
//     }

//     /// @dev Register token configuration
//     /// @param tokenAddress Target token address, 0 means eth
//     /// @param tokenConfig token configuration
//     function register(address tokenAddress, TokenConfig calldata tokenConfig) external onlyGovernance {
//         // Get registered tokenIndex by tokenAddress
//         uint index = _tokenMapping[tokenAddress];
        
//         // index == 0 means token not registered, add
//         if (index == 0) {
//             // Add tokenConfig to array
//             _tokenConfigs.push(tokenConfig);
//             // Record index + 1
//             index = _tokenConfigs.length;
//             require(index < 0x10000, "FO:too much tokenConfigs");
//             _tokenMapping[tokenAddress] = index;
//         } else {
//             // Update tokenConfig
//             _tokenConfigs[index - 1] = tokenConfig;
//         }
//     }

//     /// @dev Returns the current value of target address in the specified future
//     /// @param index Index of future
//     /// @param oraclePrice Current price from oracle, usd based, 18 decimals
//     /// @param addr Target address
//     function balanceOf(uint index, uint oraclePrice, address addr) external view override returns (uint) {
//         FutureInfo storage fi = _futures[index];
//         Account memory account = fi.accounts[addr];
//         return _balanceOf(
//             _tokenConfigs[fi.tokenIndex],
//             uint(account.balance), 
//             _decodeFloat(account.basePrice), 
//             uint(account.baseBlock),
//             oraclePrice, 
//             fi.orientation, 
//             uint(fi.lever)
//         );
//     }

//     /// @dev Find the futures of the target address (in reverse order)
//     /// @param start Find forward from the index corresponding to the given owner address 
//     /// (excluding the record corresponding to start)
//     /// @param count Maximum number of records returned
//     /// @param maxFindCount Find records at most
//     /// @param owner Target address
//     /// @return futureArray Matched futures
//     function find(
//         uint start, 
//         uint count, 
//         uint maxFindCount, 
//         address owner
//     ) external view override returns (FutureView[] memory futureArray) {
//         futureArray = new FutureView[](count);
//         // Calculate search region
//         FutureInfo[] storage futures = _futures;

//         // Loop from start to end
//         uint end = 0;
//         // start is 0 means Loop from the last item
//         if (start == 0) {
//             start = futures.length;
//         }
//         // start > maxFindCount, so end is not 0
//         if (start > maxFindCount) {
//             end = start - maxFindCount;
//         }
        
//         // Loop lookup to write qualified records to the buffer
//         for (uint index = 0; index < count && start > end;) {
//             FutureInfo storage fi = futures[--start];
//             if (uint(fi.accounts[owner].balance) > 0) {
//                 futureArray[index++] = _toFutureView(fi, start, owner);
//             }
//         }
//     }

//     /// @dev List futures
//     /// @param offset Skip previous (offset) records
//     /// @param count Return (count) records
//     /// @param order Order. 0 reverse order, non-0 positive order
//     /// @return futureArray List of futures
//     function list(
//         uint offset, 
//         uint count, 
//         uint order
//     ) external view override returns (FutureView[] memory futureArray) {
//         // Load futures
//         FutureInfo[] storage futures = _futures;
//         // Create result array
//         futureArray = new FutureView[](count);
//         uint length = futures.length;
//         uint i = 0;

//         // Reverse order
//         if (order == 0) {
//             uint index = length - offset;
//             uint end = index > count ? index - count : 0;
//             while (index > end) {
//                 FutureInfo storage fi = futures[--index];
//                 futureArray[i++] = _toFutureView(fi, index, msg.sender);
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
//                 futureArray[i++] = _toFutureView(futures[index], index, msg.sender);
//                 ++index;
//             }
//         }
//     }

//     /// @dev Create future
//     /// @param tokenAddress Target token address, 0 means eth
//     /// @param levers Levers of future
//     /// @param orientation true: call, false: put
//     function create(address tokenAddress, uint[] calldata levers, bool orientation) external override onlyGovernance {

//         // Get registered tokenIndex by tokenAddress
//         // _tokenMapping[tokenAddress] is less than 0x10000, so it can convert to uint16
//         // If tokenAddress not registered, _tokenMapping[tokenAddress] is 0, subtract by 1 will failed
//         // This make sure tokenAddress must registered
//         uint16 tokenIndex = uint16(_tokenMapping[tokenAddress] - 1);

//         // Create futures
//         for (uint i = 0; i < levers.length; ++i) {
//             uint lever = levers[i];

//             // Check if the future exists
//             uint key = _getKey(tokenAddress, lever, orientation);
//             uint index = _futureMapping[key];
//             require(index == 0, "HF:exists");

//             // Create future
//             index = _futures.length;
//             FutureInfo storage fi = _futures.push();
//             fi.tokenAddress = tokenAddress;
//             fi.lever = uint32(lever);
//             fi.orientation = orientation;
//             fi.tokenIndex = tokenIndex;

//             _futureMapping[key] = index;

//             // emit New event
//             emit New(tokenAddress, lever, orientation, index);
//         }
//     }

//     /// @dev Obtain the number of futures that have been created
//     /// @return Number of futures created
//     function getFutureCount() external view override returns (uint) {
//         return _futures.length;
//     }

//     /// @dev Get information of future
//     /// @param tokenAddress Target token address, 0 means eth
//     /// @param lever Lever of future
//     /// @param orientation true: call, false: put
//     /// @return Information of future
//     function getFutureInfo(
//         address tokenAddress, 
//         uint lever,
//         bool orientation
//     ) external view override returns (FutureView memory) {
//         uint index = _futureMapping[_getKey(tokenAddress, lever, orientation)];
//         return _toFutureView(_futures[index], index, msg.sender);
//     }

//     /// @dev Buy future
//     /// @param tokenAddress Target token address, 0 means eth
//     /// @param lever Lever of future
//     /// @param orientation true: call, false: put
//     /// @param dcuAmount Amount of paid DCU
//     function buy(
//         address tokenAddress,
//         uint lever,
//         bool orientation,
//         uint dcuAmount
//     ) external payable override {
//         return buyDirect(_futureMapping[_getKey(tokenAddress, lever, orientation)], dcuAmount);
//     }

//     /// @dev Buy future direct
//     /// @param index Index of future
//     /// @param dcuAmount Amount of paid DCU
//     function buyDirect(uint index, uint dcuAmount) public payable override {

//         require(index != 0, "HF:not exist");
//         require(dcuAmount >= 50 ether, "HF:at least 50 nest");

//         // 1. Burn dcu from user
//         //DCU(DCU_TOKEN_ADDRESS).burn(msg.sender, dcuAmount);
//         TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, FORT_VAULT_ADDRESS, dcuAmount);

//         FutureInfo storage fi = _futures[index];
//         bool orientation = fi.orientation;
        
//         // 2. Query oracle price
//         // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
//         // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
//         // When merger, s0 use recorded price, s1 use corrected by k
//         TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
//         uint oraclePrice = _queryPrice(dcuAmount, tokenConfig, orientation, msg.sender);

//         // 3. Merger price
//         Account memory account = fi.accounts[msg.sender];
//         uint basePrice = _decodeFloat(account.basePrice);
//         uint balance = uint(account.balance);
//         uint newPrice = oraclePrice;
//         if (uint(account.baseBlock) > 0) {
//             newPrice = (balance + dcuAmount) * oraclePrice * basePrice / (
//                 basePrice * dcuAmount + (balance << 64) * oraclePrice / _expMiuT(
//                     uint(orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
//                     uint(account.baseBlock)
//                 )
//             );
//         }
        
//         // 4. Update account
//         account.balance = _toUInt128(balance + dcuAmount);
//         account.basePrice = _encodeFloat(newPrice);
//         account.baseBlock = uint32(block.number);
//         fi.accounts[msg.sender] = account;

//         // emit Buy event
//         emit Buy(index, dcuAmount, msg.sender);
//     }

//     /// @dev Sell future
//     /// @param index Index of future
//     /// @param amount Amount to sell
//     function sell(uint index, uint amount) external payable override {

//         require(index != 0, "HF:not exist");
        
//         // 1. Load the future
//         FutureInfo storage fi = _futures[index];
//         bool orientation = fi.orientation;

//         // 2. Query oracle price
//         // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
//         // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
//         // When merger, s0 use recorded price, s1 use corrected by k
//         TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
//         uint oraclePrice = _queryPrice(0, tokenConfig, !orientation, msg.sender);

//         // 3. Update account
//         Account memory account = fi.accounts[msg.sender];
//         account.balance -= _toUInt128(amount);
//         fi.accounts[msg.sender] = account;

//         // 4. Mint DCU to user
//         uint value = _balanceOf(
//             tokenConfig,
//             amount, 
//             _decodeFloat(account.basePrice), 
//             uint(account.baseBlock),
//             oraclePrice, 
//             orientation, 
//             uint(fi.lever)
//         );
//         //DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, value);
//         IFortVault(FORT_VAULT_ADDRESS).transferTo(msg.sender, value);

//         // emit Sell event
//         emit Sell(index, amount, msg.sender, value);
//     }

//     /// @dev Settle future
//     /// @param index Index of future
//     /// @param addresses Target addresses
//     function settle(uint index, address[] calldata addresses) external payable override {

//         require(index != 0, "HF:not exist");

//         // 1. Load the future
//         FutureInfo storage fi = _futures[index];
//         uint lever = uint(fi.lever);
//         require(lever > 1, "HF:lever must greater than 1");

//         bool orientation = fi.orientation;
            
//         // 2. Query oracle price
//         // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
//         // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
//         // When merger, s0 use recorded price, s1 use corrected by k
//         TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
//         uint oraclePrice = _queryPrice(0, tokenConfig, !orientation, msg.sender);

//         // 3. Loop and settle
//         uint reward = 0;
//         for (uint i = addresses.length; i > 0;) {
//             address acc = addresses[--i];

//             // 4. Update account
//             Account memory account = fi.accounts[acc];
//             uint balance = _balanceOf(
//                 tokenConfig,
//                 uint(account.balance), 
//                 _decodeFloat(account.basePrice), 
//                 uint(account.baseBlock),
//                 oraclePrice, 
//                 orientation, 
//                 lever
//             );

//             // 5. Settle logic
//             // lever is great than 1, and balance less than a regular value, can be liquidated
//             // the regular value is: Max(balance * lever * 2%, MIN_VALUE)
//             uint minValue = uint(account.balance) * lever / 50;
//             if (balance < (minValue < MIN_VALUE ? MIN_VALUE : minValue)) {
//                 fi.accounts[acc] = Account(uint128(0), uint64(0), uint32(0));
//                 reward += balance;
//                 emit Settle(index, acc, msg.sender, balance);
//             }
//         }

//         // 6. Mint DCU to user
//         if (reward > 0) {
//             //DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, reward);
//             IFortVault(FORT_VAULT_ADDRESS).transferTo(msg.sender, reward);
//         }
//     }

//     // Compose key by tokenAddress, lever and orientation
//     function _getKey(
//         address tokenAddress, 
//         uint lever,
//         bool orientation
//     ) private pure returns (uint) {
//         //return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
//         require(lever < 0x100000000, "HF:lever too large");
//         return (uint(uint160(tokenAddress)) << 96) | (lever << 8) | (orientation ? 1 : 0);
//     }

//     // Query price
//     function _queryPrice(
//         uint dcuAmount, 
//         TokenConfig memory tokenConfig, 
//         bool enlarge, 
//         address payback
//     ) private returns (uint oraclePrice) {

//         // Query price from oracle
//         uint[] memory prices = _lastPriceList(tokenConfig, msg.value, payback);
        
//         // Convert to usdt based price
//         oraclePrice = prices[1];
//         uint k = calcRevisedK(uint(tokenConfig.sigmaSQ), prices[3], prices[2], oraclePrice, prices[0]);

//         // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
//         // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
//         // When merger, s0 use recorded price, s1 use corrected by k
//         if (enlarge) {
//             oraclePrice = oraclePrice * (1 ether + k + impactCost(dcuAmount)) / 1 ether;
//         } else {
//             oraclePrice = oraclePrice * 1 ether / (1 ether + k + impactCost(dcuAmount));
//         }
//     }

//     /// @dev Calculate the impact cost
//     /// @param vol Trade amount in dcu
//     /// @return Impact cost
//     function impactCost(uint vol) public pure override returns (uint) {
//         //impactCost = vol / 10000 / 1000;

//         // TODO:
//         return 0;
//         return vol / 10000000;
//     }

//     /// @dev K value is calculated by revised volatility
//     /// @param sigmaSQ sigmaSQ for token
//     /// @param p0 Last price (number of tokens equivalent to 2000 USD)
//     /// @param bn0 Block number of the price p0
//     /// @param p Latest price (number of tokens equivalent to 2000 USD)
//     /// @param bn The block number of the price p
//     function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
//         uint sigmaISQ = p * 1 ether / p0;
//         if (sigmaISQ > 1 ether) {
//             sigmaISQ -= 1 ether;
//         } else {
//             sigmaISQ = 1 ether - sigmaISQ;
//         }

//         // The left part change to: Max((p2 - p1) / p1, 0.002)
//         if (sigmaISQ > 0.002 ether) {
//             k = sigmaISQ;
//         } else {
//             k = 0.002 ether;
//         }

//         sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0);

//         if (sigmaISQ > sigmaSQ * BLOCK_TIME * 1 ether) {
//             k += _sqrt(sigmaISQ * (block.number - bn));
//         } else {
//             k += _sqrt(1 ether * BLOCK_TIME * sigmaSQ * (block.number - bn));
//         }

//         // TODO:
//         k = 0;
//     }

//     function _sqrt(uint256 x) private pure returns (uint256) {
//         unchecked {
//             if (x == 0) return 0;
//             else {
//                 uint256 xx = x;
//                 uint256 r = 1;
//                 if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
//                 if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
//                 if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
//                 if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
//                 if (xx >= 0x100) { xx >>= 8; r <<= 4; }
//                 if (xx >= 0x10) { xx >>= 4; r <<= 2; }
//                 if (xx >= 0x8) { r <<= 1; }
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1;
//                 r = (r + x / r) >> 1; // Seven iterations should be enough
//                 uint256 r1 = x / r;
//                 return (r < r1 ? r : r1);
//             }
//         }
//     }

//     /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
//     /// @param value Destination uint value
//     /// @return float format
//     function _encodeFloat(uint value) private pure returns (uint64) {

//         uint exponent = 0; 
//         while (value > 0x3FFFFFFFFFFFFFF) {
//             value >>= 4;
//             ++exponent;
//         }
//         return uint64((value << 6) | exponent);
//     }

//     /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
//     /// @param floatValue fraction value
//     /// @return decode format
//     function _decodeFloat(uint64 floatValue) private pure returns (uint) {
//         return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
//     }

//     // Convert uint to uint128
//     function _toUInt128(uint value) private pure returns (uint128) {
//         require(value < 0x100000000000000000000000000000000, "FEO:can't convert to uint128");
//         return uint128(value);
//     }

//     // Convert uint to int128
//     function _toInt128(uint v) private pure returns (int128) {
//         require(v < 0x80000000000000000000000000000000, "FEO:can't convert to int128");
//         return int128(int(v));
//     }

//     // Convert int128 to uint
//     function _toUInt(int128 v) private pure returns (uint) {
//         require(v >= 0, "FEO:can't convert to uint");
//         return uint(int(v));
//     }
    
//     // Calculate net worth
//     function _balanceOf(
//         TokenConfig memory tokenConfig,
//         uint balance,
//         uint basePrice,
//         uint baseBlock,
//         uint oraclePrice, 
//         bool ORIENTATION, 
//         uint LEVER
//     ) private view returns (uint) {

//         if (balance > 0) {
//             uint left;
//             uint right;
//             // Call
//             if (ORIENTATION) {
//                 left = balance + (LEVER << 64) * balance * oraclePrice / basePrice
//                         / _expMiuT(uint(tokenConfig.miuLong), baseBlock);
//                 right = balance * LEVER;
//             } 
//             // Put
//             else {
//                 left = balance * (1 + LEVER);
//                 right = (LEVER << 64) * balance * oraclePrice / basePrice 
//                         / _expMiuT(uint(tokenConfig.miuShort), baseBlock);
//             }

//             if (left > right) {
//                 balance = left - right;
//             } else {
//                 balance = 0;
//             }
//         }

//         return balance;
//     }

//     // Calculate e^μT
//     function _expMiuT(uint miu, uint baseBlock) private view returns (uint) {
//         // return _toUInt(ABDKMath64x64.exp(
//         //     _toInt128((orientation ? MIU_LONG : MIU_SHORT) * (block.number - baseBlock) * BLOCK_TIME)
//         // ));

//         // Using approximate algorithm: x*(1+rt)
//         return miu * (block.number - baseBlock) * BLOCK_TIME + 0x10000000000000000;
//     }

//     // Convert FutureInfo to FutureView
//     function _toFutureView(FutureInfo storage fi, uint index, address owner) private view returns (FutureView memory) {
//         Account memory account = fi.accounts[owner];
//         return FutureView(
//             index,
//             fi.tokenAddress,
//             uint(fi.lever),
//             fi.orientation,
//             uint(account.balance),
//             _decodeFloat(account.basePrice),
//             uint(account.baseBlock)
//         );
//     }
// }
