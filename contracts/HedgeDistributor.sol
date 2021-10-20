// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICoFiXPool.sol";

import "./libs/TransferHelper.sol";

import "./interfaces/IHedgeVaultForStaking.sol";

import "./HedgeFrequentlyUsed.sol";
import "./DCU.sol";

/// @dev DCU分发合约
contract HedgeDistributor is HedgeFrequentlyUsed, ICoFiXPool {

    //     ** rinkeby@20210728.js **
    // usdt: 0x2d750210c0b5343a0b79beff8F054C9add7d2411
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // peth: 0x4D4B378eFbeb7eE15Aa498F3383C9949391557e0
    // pusd: 0x740ed84037E5d2F650b585759623EBC4de849021
    // usdc: 0xB64825a6bA80d65886b5123f5170ddffc935D9DE
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    // cnode: 0x91566410cC6E9F6579e4132909F597676D5C1FB2
    // cofi: 0x61EA050b28Ccca539F0faf79Fd26F6Df31b9f15B
    // cofixGovernance: 0x4A01418AFAfD5d7870130F1cA2967BaD09863539
    // cofixDAO: 0x2720dF961723568062A96F9f5310d8ab408bfFfc
    // cofixRouter: 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9
    // cofixVaultForStaking: 0x11839c81beBBC82686b0052Cb6F03E9Ae58A9704
    // cofixController: 0x59c2EAF8FC22C10C2EB79Be3c23c2916BD0ec81e
    // proxyAdmin: 0x533b91f72564422c7f9a735d838f4171cB30e033
    // cofixControllerImpl: 0xB6B199A0925a398E02fE0C46f7a86c6B27eB57Ff
    // usdtPair: 0xf749fA2B6E75F9EfBa8427eA86036f38A7173F9C
    // hbtcPair: 0xB042c57997a561FB93C510BA1811927B78452EAF
    // nestPair: 0x6FAc11eE801713460B2b9Fe089f473c48756D45d
    // cofiPair: 0x45579827334583680c33ae9110C6a65806DB6EC7
    // ethAnchor: 0xD93F55F65316de63497163e4d2FD0390A1805c35
    // usdAnchor: 0xdCa0d07422691f286f5CE641FF4F40D5979BC0D7
    // xeth: 0xe884Cc2774f90065f07E79B7673dD93cC7Cee30C
    // xpeth: 0x142d684B614D42c2a93EB07C0d067c2db195Bb34
    // xusdt: 0x1eDBAFb57D9Ae6808F9746E2bEf0C491351B456F
    // xpusd: 0x98F718Db4fA72F584C9dcA958c1fa7f7665Fb9a7
    // xusdc: 0x738029DD7dB8872eA9f4FF72eC5f06c31DED0948
    // uni: 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984
    // uniswapV3PoolAdapter-uni: 0xCF483FF2D14EFd67f2c78cfe3430488313191569
    // cofixSinglePool-nest: 0x503B77BB77182b5f2a19Bacc5285af0edC5126FF
    // cofixSinglePool-cofi: 0x4115F0e23AbDd94AEF944e5Aba1362b43d3d6638

    address constant COFIX_ROUTER_ADDRESS = 0x9f7997EFb0aF6f5e370dea99b1941D73330825C9;

    // address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    address constant NEST_TOKEN_ADDRESS = 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25;

    //uint constant K = 30000000 ether * 30000000 ether;
    uint constant K = 3000000 ether * 3000000 ether;

    constructor() {
    }

    // function setNestTokenAddress(address nestTokenAddress) external {
    //     NEST_TOKEN_ADDRESS = nestTokenAddress;
    // }

    function deposit(uint nestAmount, uint dcuAmount) external {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestAmount);
        TransferHelper.safeTransferFrom( DCU_TOKEN_ADDRESS, msg.sender, address(this),  dcuAmount);
        require(
            IERC20(NEST_TOKEN_ADDRESS).balanceOf(address(this)) * 
            IERC20(DCU_TOKEN_ADDRESS).balanceOf(address(this)) <= K,
            "HD:too much"
        );
    }

    /// @dev Add liquidity and mint xtoken
    /// @param token Target token address
    /// @param to The address to receive xtoken
    /// @param amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param amountToken The amount of Token added to pool
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function mint(
        address token,
        address to, 
        uint amountETH, 
        uint amountToken,
        address payback
    ) external payable override returns (
        address xtoken,
        uint liquidity
    ) {
        revert("HD:not support");
    }

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// @param token The address of ERC20 Token
    /// @param to The target address receiving the Token
    /// @param liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountETHOut The real amount of ETH transferred from the pool
    /// @return amountTokenOut The real amount of Token transferred from the pool
    function burn(
        address token,
        address to, 
        uint liquidity, 
        address payback
    ) external payable override returns (
        uint amountETHOut,
        uint amountTokenOut 
    ) {
        revert("HD:not support");
    }
    
    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param amountIn The exact amount of Token a trader want to swap into pool
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable override returns (
        uint amountOut, 
        uint mined
    ) {
        require(msg.sender == COFIX_ROUTER_ADDRESS, "HD:only for router");
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
        }
        
        amountOut = _swap(src, dest, amountIn, to);
    }

    function swapForDCU(uint nestAmount) external {
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, address(this), nestAmount);
        _swap(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, nestAmount, msg.sender);
    }

    function swapForNEST(uint dcuAmount) external {
        TransferHelper.safeTransferFrom(DCU_TOKEN_ADDRESS, msg.sender, address(this), dcuAmount);
        _swap(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, dcuAmount, msg.sender);
    }

    function swapExactDCU(uint dctAmount) external {
        _swapExact(NEST_TOKEN_ADDRESS, DCU_TOKEN_ADDRESS, dctAmount, msg.sender);
    }

    function swapExactNEST(uint nestAmount) external {
       _swap(DCU_TOKEN_ADDRESS, NEST_TOKEN_ADDRESS, nestAmount, msg.sender);
    }

    function _swap(address src, address dest, uint amountIn, address to) private returns (uint amountOut) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountOut = balance1 - K / balance0;
        TransferHelper.safeTransfer(dest, to, amountOut);
    }

    function _swapExact(address src, address dest, uint amountOut, address to) private returns (uint amountIn) {
        uint balance0 = IERC20(src).balanceOf(address(this));
        uint balance1 = IERC20(dest).balanceOf(address(this));

        amountIn = K / (balance1 - amountOut) - balance0;
        TransferHelper.safeTransferFrom(src, msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(dest, to, amountOut);
    }

    /// @dev Gets the token address of the share obtained by the specified token market making
    /// @param token Target token address
    /// @return If the fund pool supports the specified token, return the token address of the market share
    function getXToken(address token) external view override returns (address) {
        revert("HD:not support");
    }
}
