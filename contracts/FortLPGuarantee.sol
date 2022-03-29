// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortLPGuarantee.sol";

import "./custom/ChainParameter.sol";
import "./custom/HedgeFrequentlyUsed.sol";
import "./custom/FortPriceAdapter.sol";

import "./DCU.sol";

/// @dev European option
contract FortOptions is ChainParameter, HedgeFrequentlyUsed, FortPriceAdapter, IFortLPGuarantee {

    struct Guarantee {
        uint32 owner;
        uint56 x0;
        uint56 y0;
        uint56 balance;
        uint32 exerciseBlock;
        uint16 tokenIndex;
    }

    // token registration information
    struct TokenRegistration {
        TokenConfig tokenConfig;
        address tokenAddress;
    }

    // 64bits 1
    int128 constant ONE = 0x10000000000000000;

    Guarantee[] _guarantees;

    // Registered account address mapping
    mapping(address=>uint) _accountMapping;

    // Registered accounts
    address[] _accounts;

    // token to index mapping
    mapping(address=>uint) _tokenMapping;

    // token registration information array
    TokenRegistration[] _tokenRegistrations;

    constructor() {
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IHedgeGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _accounts.push();
    }

    /// @dev Register token information
    /// @param tokenAddress Target token address, 0 means eth
    /// @param tokenConfig token configuration
    function register(address tokenAddress, TokenConfig calldata tokenConfig) external onlyGovernance {

        // Get index + 1 by tokenAddress
        uint index = _tokenMapping[tokenAddress];
        
        // index == 0 means token not registered, add
        if (index == 0) {
            // Add TokenRegistration to array
            _tokenRegistrations.push(TokenRegistration(tokenConfig, tokenAddress));
            // Record index + 1
            index = _tokenRegistrations.length;
            require(index < 0x10000, "FO:too much tokenRegistrations");
            _tokenMapping[tokenAddress] = index;
        } else {
            _tokenRegistrations[index - 1].tokenConfig = tokenConfig;
        }
    }

    /// @dev Returns the share of the specified option for target address
    /// @param index Index of the option
    /// @param addr Target address
    function balanceOf(uint index, address addr) external view override returns (uint) {
        Guarantee memory guarantee = _guarantees[index];
        if (uint(guarantee.owner) == getAccountIndex(addr)) {
            return _decodeFloat(guarantee.balance);
        }
        return 0;
    }

    /// @dev Find the options of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return guaranteeArray Matched guarantee array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (GuaranteeView[] memory guaranteeArray) {
        
        guaranteeArray = new GuaranteeView[](count);
        
        // Calculate search region
        Guarantee[] storage guarantees = _guarantees;
        uint i = guarantees.length;
        uint end = 0;
        if (start > 0) {
            i = start;
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }
        
        uint ownerIndex = getAccountIndex(owner);
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && i > end;) {
            Guarantee storage guarantee = guarantees[--i];
            if (uint(guarantee.owner) == ownerIndex) {
                guaranteeArray[index++] = _toGuaranteeView(guarantee, i);
            }
        }
    }

    /// @dev List guarantee
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return guaranteeArray Matched option array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (GuaranteeView[] memory guaranteeArray) {

        // Load guarantees
        Guarantee[] storage guarantees = _guarantees;
        // Create result array
        guaranteeArray = new GuaranteeView[](count);
        uint length = guarantees.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Guarantee storage guarantee = guarantees[--index];
                guaranteeArray[i++] = _toGuaranteeView(guarantee, index);
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                guaranteeArray[i++] = _toGuaranteeView(guarantees[index], index);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of guarantees that have been opened
    /// @return Number of guarantees opened
    function getGuaranteeCount() external view override returns (uint) {
        return _guarantees.length;
    }

    /// @dev Open option
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param y0 y0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    function open(
        uint tokenIndex,
        uint x0,
        uint y0,
        uint exerciseBlock,
        uint dcuAmount
    ) external payable override {

        TokenConfig memory tokenConfig = _tokenRegistrations[tokenIndex].tokenConfig;

        // 1. Query price from oracle
        // TODO: verify oraclePrice
        uint oraclePrice = _latestPrice(tokenConfig, msg.value, msg.sender);

        // 2. Calculate the amount of option
        uint amount = _estimate(tokenConfig, x0, y0, exerciseBlock, dcuAmount);

        // 3. Open
        // Emit open event
        //emit Open(_options.length, dcuAmount, msg.sender, amount);
        // Add option to array
        _guarantees.push(Guarantee(
            //uint32 owner;
            uint32(_addressIndex(msg.sender)),
            //uint112 balance;
            _encodeFloat(x0),
            _encodeFloat(y0),
            _encodeFloat(amount),
            uint32(exerciseBlock),
            uint16(tokenIndex)
        ));

        // 4. Burn DCU
        DCU(DCU_TOKEN_ADDRESS).burn(msg.sender, dcuAmount);
    }

    /// @dev Estimate the amount of option
    /// @param tokenIndex Target token index
    /// @param x0 x0
    /// @param y0 y0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function estimate(
        uint tokenIndex,
        uint x0,
        uint y0,
        uint exerciseBlock,
        uint dcuAmount
    ) external view override returns (uint amount) {
        return _estimate(
            _tokenRegistrations[tokenIndex].tokenConfig,
            x0,
            y0,
            exerciseBlock,
            dcuAmount
        );
    }
    
    /// @dev Exercise guarantee
    /// @param index Index of guarantee
    /// @param amount Amount of guarantee to exercise
    function exercise(uint index, uint amount) external payable override {

        // 1. Load the option
        Guarantee storage guarantee = _guarantees[index];
        address owner = _accounts[uint(guarantee.owner)];
        uint exerciseBlock = uint(guarantee.exerciseBlock);
        uint x0 = _decodeFloat(guarantee.x0);
        uint y0 = _decodeFloat(guarantee.y0);

        TokenConfig memory tokenConfig = _tokenRegistrations[guarantee.tokenIndex].tokenConfig;

        if (block.number < exerciseBlock) {
            exerciseBlock = block.number;
        }

        // 2. Deduct the specified amount
        guarantee.balance = _encodeFloat(_decodeFloat(guarantee.balance) - amount);

        // 3. Find the price by specified block from oracle
        uint oraclePrice = _findPrice(tokenConfig, exerciseBlock, msg.value, msg.sender);

        // (St * y0 + x0 - 2 ^(St*x0 * y0))
        uint gain = oraclePrice * y0 + x0 - (_sqrt(oraclePrice * x0 * y0) << 1);

        // 5. If win, mint DCU to user
        if (gain > 0) {
            DCU(DCU_TOKEN_ADDRESS).mint(owner, gain);
        }

        // emit Exercise event
        //emit Exercise(index, amount, owner, gain);
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) public view returns (address) {
        return _accounts[index];
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) public view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint) {
        return _accounts.length;
    }

    // Convert to GuaranteeView
    function _toGuaranteeView(Guarantee storage guarantee, uint index) private view returns (GuaranteeView memory) {
        return GuaranteeView(
            index,
            _decodeFloat(guarantee.x0),
            _decodeFloat(guarantee.y0),
            _decodeFloat(guarantee.balance),
            _accounts[uint(guarantee.owner)],
            guarantee.exerciseBlock,
            guarantee.tokenIndex
        );
    }

    // Convert uint to uint112
    function _toUInt112(uint v) private pure returns (uint112) {
        require(v < 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF,"HO:can't convert to uint112");
        return uint112(v);
    }

    /// @dev Estimate the amount of option
    /// @param x0 x0
    /// @param y0 y0
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function _estimate(
        TokenConfig memory tokenConfig,
        uint x0,
        uint y0,
        uint exerciseBlock,
        uint dcuAmount
    ) private view returns (uint amount) {

        require(exerciseBlock > block.number + MIN_PERIOD, "FEO:exerciseBlock too small");
        uint T = (exerciseBlock - block.number) * BLOCK_TIME;

        // 1. Calculate option price
        //uint v = 
        //int128 sigmaSQ_T = _d18TOb64(uint(tokenConfig.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(tokenConfig.miuLong) * T);
        //int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 tmp = ABDKMath64x64.exp(miu_T >> 1) - ONE;
        tmp = ABDKMath64x64.mul(tmp, tmp);
        uint v = _toUInt(ABDKMath64x64.mul(tmp, tmp)) * x0;

        // 3. Calculate the amount of option
        amount = dcuAmount * (1 << 64) / v;
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
    
    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "HO:!accounts");
            _accounts.push(addr);
        }

        return index;
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    // Convert uint to int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x80000000000000000000000000000000, "FEO:can't convert to int128");
        return int128(int(v));
    }

    // Convert int128 to uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "FEO:can't convert to uint");
        return uint(int(v));
    }
}
