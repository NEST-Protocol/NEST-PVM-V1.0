// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./libs/ABDKMath64x64.sol";

import "./interfaces/IFortOptions.sol";

import "./custom/ChainParameter.sol";
import "./custom/HedgeFrequentlyUsed.sol";
import "./custom/FortPriceAdapter.sol";

import "./DCU.sol";

/// @dev European option
contract FortOptions is ChainParameter, HedgeFrequentlyUsed, FortPriceAdapter, IFortOptions {

    /// @dev Option structure
    struct Option {
        uint32 owner;
        uint112 balance;
        uint16 tokenIndex;
        uint56 strikePrice;
        bool orientation;
        uint32 exerciseBlock;
    }

    // token registration information
    struct TokenRegistration {
        TokenConfig tokenConfig;
        address tokenAddress;
    }

    // 64bits 1
    int128 constant ONE = 0x10000000000000000;

    // 64bits 50000
    uint constant V50000 = 0x0C3500000000000000000;

    // Proportion of option selling value, 10000 basis. 9500
    uint constant SELL_RATE = 9500;

    // Option array
    Option[] _options;

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
        Option memory option = _options[index];
        if (uint(option.owner) == getAccountIndex(addr)) {
            return uint(option.balance);
        }
        return 0;
    }

    /// @dev Find the options of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return optionArray Matched option array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (OptionView[] memory optionArray) {
        
        optionArray = new OptionView[](count);
        
        // Calculate search region
        Option[] storage options = _options;
        uint i = options.length;
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
            Option storage option = options[--i];
            if (uint(option.owner) == ownerIndex) {
                optionArray[index++] = _toOptionView(option, i);
            }
        }
    }

    /// @dev List options
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return optionArray Matched option array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (OptionView[] memory optionArray) {

        // Load options
        Option[] storage options = _options;
        // Create result array
        optionArray = new OptionView[](count);
        uint length = options.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Option storage option = options[--index];
                optionArray[i++] = _toOptionView(option, index);
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
                optionArray[i++] = _toOptionView(options[index], index);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of European options that have been opened
    /// @return Number of European options opened
    function getOptionCount() external view override returns (uint) {
        return _options.length;
    }

    /// @dev Open option
    /// @param tokenAddress Target token address, 0 means eth
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    function open(
        address tokenAddress,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external payable override {

        // _tokenMapping[tokenAddress] > 0 means token registered
        uint tokenIndex = _tokenMapping[tokenAddress] - 1;
        TokenConfig memory tokenConfig = _tokenRegistrations[tokenIndex].tokenConfig;

        // 1. Query price from oracle
        uint oraclePrice = _latestPrice(tokenConfig, msg.value, msg.sender);

        // 2. Calculate the amount of option
        uint amount = _estimate(tokenConfig, oraclePrice, strikePrice, orientation, exerciseBlock, dcuAmount);

        // 3. Open
        // Emit open event
        emit Open(_options.length, dcuAmount, msg.sender, amount);
        // Add option to array
        _options.push(Option(
            //uint32 owner;
            uint32(_addressIndex(msg.sender)),
            //uint112 balance;
            _toUInt112(amount),
            uint16(tokenIndex),
            //uint56 strikePrice;
            _encodeFloat(strikePrice),
            //bool orientation;
            orientation,
            //uint32 exerciseBlock;
            uint32(exerciseBlock)
        ));

        // 4. Burn DCU
        DCU(DCU_TOKEN_ADDRESS).burn(msg.sender, dcuAmount);
    }

    /// @dev Estimate the amount of option
    /// @param tokenAddress Target token address, 0 means eth
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function estimate(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) external view override returns (uint amount) {
        return _estimate(
            _tokenRegistrations[_tokenMapping[tokenAddress] - 1].tokenConfig,
            oraclePrice,
            strikePrice,
            orientation,
            exerciseBlock,
            dcuAmount
        );
    }
    
    /// @dev Exercise option
    /// @param index Index of option
    /// @param amount Amount of option to exercise
    function exercise(uint index, uint amount) external payable override {

        // 1. Load the option
        Option storage option = _options[index];
        address owner = _accounts[uint(option.owner)];
        uint strikePrice = _decodeFloat(option.strikePrice);
        bool orientation = option.orientation;
        uint exerciseBlock = uint(option.exerciseBlock);

        TokenConfig memory tokenConfig = _tokenRegistrations[option.tokenIndex].tokenConfig;

        require(block.number >= exerciseBlock, "FEO:at maturity");

        // 2. Deduct the specified amount
        option.balance = _toUInt112(uint(option.balance) - amount);

        // 3. Find the price by specified block from oracle
        uint oraclePrice = _findPrice(tokenConfig, exerciseBlock, msg.value, msg.sender);

        // 4. Calculate the number of DCU that can be obtained
        uint gain = 0;
        // Call option
        if (orientation) {
            // Win
            if (oraclePrice > strikePrice) {
                gain = amount * (oraclePrice - strikePrice) / USDT_BASE;
            }
        } 
        // Put option
        else {
            // Win
            if (oraclePrice < strikePrice) {
                gain = amount * (strikePrice - oraclePrice) / USDT_BASE;
            }
        }

        // 5. If win, mint DCU to user
        if (gain > 0) {
            DCU(DCU_TOKEN_ADDRESS).mint(owner, gain);
        }

        // emit Exercise event
        emit Exercise(index, amount, owner, gain);
    }

    /// @dev Sell option
    /// @param index Index of option
    /// @param amount Amount of option to sell
    function sell(uint index, uint amount) external payable override {
        // Sell formula: vt=Max(ct(T,K)*0.95, 0). 
        // ct(K,T) Is the price of option present
        // Note: No less than 1% condition

        // 1. Load the option
        Option storage option = _options[index];
        address owner = _accounts[uint(option.owner)];
        require(owner == msg.sender, "FO:not owner");
        uint strikePrice = _decodeFloat(option.strikePrice);
        bool orientation = option.orientation;
        uint exerciseBlock = uint(option.exerciseBlock);

        TokenConfig memory tokenConfig = _tokenRegistrations[option.tokenIndex].tokenConfig;

        // 2. Deduct the specified amount
        option.balance = _toUInt112(uint(option.balance) - amount);

        // 3. Query price from oracle
        uint oraclePrice = _latestPrice(tokenConfig, msg.value, msg.sender);

        // 4. Calculate option price
        uint dcuAmount = amount * _calcV(
            tokenConfig, 
            oraclePrice,
            strikePrice,
            orientation,
            exerciseBlock
        ) * SELL_RATE / (USDT_BASE * 0x27100000000000000000); 
        //(USDT_BASE * 10000 << 64);

        if (dcuAmount > 0) {
            DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, dcuAmount);
        }

        // emit Sell event
        emit Sell(index, amount, msg.sender, dcuAmount);
    }

    /// @dev Calculate option price
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @return v Option price. Need to divide (USDT_BASE << 64)
    function calcV(
        address tokenAddress,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock
    ) public view override returns (uint v) {
        return _calcV(
            _tokenRegistrations[_tokenMapping[tokenAddress] - 1].tokenConfig,
            oraclePrice,
            strikePrice,
            orientation,
            exerciseBlock
        );
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

    // Convert to OptionView
    function _toOptionView(
        Option storage option, 
        uint index
    ) private view returns (OptionView memory) {
        return OptionView(
            index,
            _tokenRegistrations[option.tokenIndex].tokenAddress,
            _decodeFloat(option.strikePrice),
            option.orientation,
            uint(option.exerciseBlock),
            option.balance,
            _accounts[uint(option.owner)]
        );
    }

    // Convert 18 decimal points to 64 binary points
    function _d18TOb64(uint v) private pure returns (int128) {
        require(v < 0x6F05B59D3B200000000000000000000, "FEO:can't convert to 64bits");
        return int128(int((v << 64) / 1 ether));
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

    // Convert uint to uint112
    function _toUInt112(uint v) private pure returns (uint112) {
        require(v < 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF,"HO:can't convert to uint112");
        return uint112(v);
    }

    // Calculate standard normal distribution by table
    function _snd(int128 x) private pure returns (int128) {
        uint[28] memory table = [
            /* */ ///////////////////// STANDARD NORMAL TABLE //////////////////////////
            /* */ 0x174A15BF143412A8111C0F8F0E020C740AE6095807CA063B04AD031E018F0000, //
            ///// 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D8, //
            /* */ 0x2F8C2E0F2C912B1229922811268F250B23872202207D1EF61D6F1BE61A5D18D4, //
            /* */ 0x46A2453C43D4426B41003F943E263CB63B4539D3385F36EA357333FB32823108, //
            /* */ 0x5C0D5AC5597B582F56E05590543E52EA5194503C4EE24D874C294ACA49694807, //
            /* */ 0x6F6C6E466D1F6BF56AC9699B686A6738660364CC6392625761195FD95E975D53, //
            /* */ 0x807E7F7F7E7D7D797C737B6A7A5F79517841772F761A750373E972CD71AF708E, //
            /* */ 0x8F2A8E518D768C998BB98AD789F2890B88218736864785568463836E8276817B, //
            /* */ 0x9B749AC19A0B9953989997DD971E965D959A94D4940C9342927591A690D49000, //
            ///// 0xA57CA4ECA459A3C4A32EA295A1FAA15CA0BDA01C9F789ED29E2A9D809CD39C25, //
            /* */ 0xA57CA4ECA459A3C4A32EA295A1FAA15DA0BDA01C9F789ED29E2A9D809CD39C25, //
            /* */ 0xAD78AD07AC93AC1EABA7AB2EAAB3AA36A9B8A937A8B5A830A7AAA721A697A60B, //
            /* */ 0xB3AAB353B2FAB2A0B245B1E7B189B128B0C6B062AFFDAF96AF2DAEC2AE56ADE8, //
            /* */ 0xB859B818B7D6B793B74EB708B6C0B678B62EB5E2B595B547B4F7B4A6B454B400, //
            /* */ 0xBBCDBB9EBB6EBB3CBB0ABAD7BAA2BA6DBA36B9FFB9C6B98CB951B915B8D8B899, //
            /* */ 0xBE49BE27BE05BDE2BDBEBD99BD74BD4DBD26BCFEBCD5BCACBC81BC56BC29BBFC, //
            /* */ 0xC006BFEEBFD7BFBEBFA5BF8CBF72BF57BF3CBF20BF03BEE6BEC8BEA9BE8ABE69, //
            /* */ 0xC135C126C116C105C0F4C0E3C0D1C0BFC0ACC099C086C072C05DC048C032C01C, //
            /* */ 0xC200C1F5C1EBC1E0C1D5C1C9C1BEC1B1C1A5C198C18BC17EC170C162C154C145, //
            /* */ 0xC283C27CC275C26EC267C260C258C250C248C240C238C22FC226C21DC213C20A, //
            /* */ 0xC2D6C2D2C2CDC2C9C2C5C2C0C2BBC2B6C2B1C2ACC2A7C2A1C29BC295C28FC289, //
            /* */ 0xC309C306C304C301C2FEC2FCC2F9C2F6C2F2C2EFC2ECC2E8C2E5C2E1C2DEC2DA, //
            /* */ 0xC328C326C325C323C321C320C31EC31CC31AC318C316C314C312C310C30EC30B, //
            /* */ 0xC33AC339C338C337C336C335C334C333C332C331C330C32EC32DC32CC32AC329, //
            /* */ 0xC344C343C343C342C342C341C341C340C33FC33FC33EC33DC33DC33CC33BC33A, //
            /* */ 0xC34AC349C349C349C348C348C348C348C347C347C346C346C346C345C345C344, //
            /* */ 0xC34DC34DC34CC34CC34CC34CC34CC34CC34BC34BC34BC34BC34BC34AC34AC34A, //
            /* */ 0xC34EC34EC34EC34EC34EC34EC34EC34EC34EC34EC34DC34DC34DC34DC34DC34D, //
            /* */ 0xC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34FC34EC34E, //
            /* */ 0xC350C350C350C350C350C350C34FC34FC34FC34FC34FC34FC34FC34FC34FC34F  //
            /* */ //////////////////// MADE IN CHINA 2021-08-24 ////////////////////////
        ];

        uint ux = uint(int(x < 0 ? -x : x)) * 100;
        uint i = ux >> 64;
        uint v = V50000;

        if (i < 447) {
            v = uint((table[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF) << 64;
            v = (
                    (
                        (
                            (uint((table[(i + 1) >> 4] >> (((i + 1) & 0xF) << 4)) & 0xFFFF) << 64)
                            - v
                        ) * (ux & 0xFFFFFFFFFFFFFFFF) //(ux - (i << 64))
                    ) >> 64
                ) + v;
        }

        if (x > 0) {
            v = V50000 + v;
        } else {
            v = V50000 - v;
        }

        return int128(int(v / 100000));
    }

    /// @dev Estimate the amount of option
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @param dcuAmount Amount of paid DCU
    /// @return amount Amount of option
    function _estimate(
        TokenConfig memory tokenConfig,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock,
        uint dcuAmount
    ) private view returns (uint amount) {

        require(exerciseBlock > block.number + MIN_PERIOD, "FEO:exerciseBlock too small");

        // 1. Calculate option price
        uint v = _calcV(
            tokenConfig, 
            oraclePrice,
            strikePrice,
            orientation,
            exerciseBlock
        );

        // 2. Correct option price
        if (orientation) {
            //v = _calcVc(config, oraclePrice, T, strikePrice);
            // Vc>=S0*1%; Vp>=K*1%
            // require(v * 100 >> 64 >= oraclePrice, "FEO:vc must greater than S0*1%");
            if (v * 100 >> 64 < oraclePrice) {
                v = oraclePrice * 0x10000000000000000 / 100;
            }
        } else {
            //v = _calcVp(config, oraclePrice, T, strikePrice);
            // Vc>=S0*1%; Vp>=K*1%
            // require(v * 100 >> 64 >= strikePrice, "FEO:vp must greater than K*1%");
            if (v * 100 >> 64 < strikePrice) {
                v = strikePrice * 0x10000000000000000 / 100;
            }
        }

        // 3. Calculate the amount of option
        amount = (USDT_BASE << 64) * dcuAmount / v;
    }

    /// @dev Calculate option price
    /// @param oraclePrice Current price from oracle
    /// @param strikePrice The exercise price set by the user. During settlement, the system will compare the 
    /// current price of the subject matter with the exercise price to calculate the user's profit and loss
    /// @param orientation true: call, false: put
    /// @param exerciseBlock After reaching this block, the user will exercise manually, and the block will be
    /// recorded in the system using the block number
    /// @return v Option price. Need to divide (USDT_BASE << 64)
    function _calcV(
        TokenConfig memory tokenConfig,
        uint oraclePrice,
        uint strikePrice,
        bool orientation,
        uint exerciseBlock
    ) private view returns (uint v) {

        // Convert the total time according to the average block out time
        uint T = (exerciseBlock - block.number) * BLOCK_TIME;
        v = orientation 
            ? _calcVc(tokenConfig, oraclePrice, T, strikePrice) 
            : _calcVp(tokenConfig, oraclePrice, T, strikePrice);
    }

    // Calculate option price for call
    function _calcVc(TokenConfig memory tokenConfig, uint S0, uint T, uint K) private pure returns (uint vc) {

        int128 sigmaSQ_T = _d18TOb64(uint(tokenConfig.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(tokenConfig.miuLong) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(ABDKMath64x64.mul(
            //ABDKMath64x64.exp(miu_T), 
            // Use approximate calculation method: x*(1+rt)
            // by chenf 2021-12-28 15:27
            miu_T + ONE,
            ABDKMath64x64.sub(
                ONE,
                _snd(ABDKMath64x64.sub(d, sigma_t))
            )
        )) * S0;
        uint right = _toUInt(ABDKMath64x64.sub(ONE, _snd(d))) * K;
        
        vc = left > right ? left - right : 0;
    }

    // Calculate option price for put
    function _calcVp(TokenConfig memory tokenConfig, uint S0, uint T, uint K) private pure returns (uint vp) {

        int128 sigmaSQ_T = _d18TOb64(uint(tokenConfig.sigmaSQ) * T);
        int128 miu_T = _toInt128(uint(tokenConfig.miuShort) * T);
        int128 sigma_t = ABDKMath64x64.sqrt(sigmaSQ_T);
        int128 D1 = _D1(S0, K, sigmaSQ_T, miu_T);
        int128 d = ABDKMath64x64.div(D1, sigma_t);

        uint left = _toUInt(_snd(d)) * K;
        uint right = _toUInt(ABDKMath64x64.mul(
            //ABDKMath64x64.exp(miu_T), 
            // Use approximate calculation method: x*(1+rt)
            // by chenf 2021-12-28 15:27
            miu_T + ONE,
            _snd(ABDKMath64x64.sub(d, sigma_t))
        )) * S0;

        vp = left > right ? left - right : 0;
    }

    // d1 in formula, Because didn't divide by σ, So it's named D1
    function _D1(uint S0, uint K, int128 sigmaSQ_T, int128 miu_T) private pure returns (int128) {

        //require(K < 0x1000000000000000000000000000000000000000000000000, "FEO:K can't ROL 64bits");
        return
            ABDKMath64x64.sub(
                ABDKMath64x64.add(
                    ABDKMath64x64.ln(_toInt128(K * 0x10000000000000000 / S0)),
                    sigmaSQ_T >> 1
                ),
                miu_T
            );
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
}
