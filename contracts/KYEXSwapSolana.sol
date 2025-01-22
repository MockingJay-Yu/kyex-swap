// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/IWZETA.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/IZRC20.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/UniversalContract.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "libraries/TransferHelper.sol";
import "libraries/error/Errors.sol";
import "libraries/event/Events.sol";
import "libraries/BytesLib.sol";

/*
██╗░░██╗██╗░░░██╗███████╗██╗░░██╗
██║░██╔╝╚██╗░██╔╝██╔════╝╚██╗██╔╝
█████═╝░░╚████╔╝░█████╗░░░╚███╔╝░
██╔═██╗░░░╚██╔╝░░██╔══╝░░░██╔██╗░
██║░╚██╗░░░██║░░░███████╗██╔╝╚██╗
╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝

░█████╗░██████╗░░█████╗░░██████╗░██████╗░░░░░░░█████╗░██╗░░██╗░█████╗░██╗███╗░░██╗
██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝░░░░░░██╔══██╗██║░░██║██╔══██╗██║████╗░██║
██║░░╚═╝██████╔╝██║░░██║╚█████╗░╚█████╗░█████╗██║░░╚═╝███████║███████║██║██╔██╗██║
██║░░██╗██╔══██╗██║░░██║░╚═══██╗░╚═══██╗╚════╝██║░░██╗██╔══██║██╔══██║██║██║╚████║
╚█████╔╝██║░░██║╚█████╔╝██████╔╝██████╔╝░░░░░░╚█████╔╝██║░░██║██║░░██║██║██║░╚███║
░╚════╝░╚═╝░░╚═╝░╚════╝░╚═════╝░╚═════╝░░░░░░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝

░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░
██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗
╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝
░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░
██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░
╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░
*/

/**
 * @title KYEX CrossChain Swap
 * @author KYEX-TEAM
 * @dev KYEX Mainnet ZETACHAIN Smart Contract V1
 */
contract KYEXSwapZeta is
    UniversalContract,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    ///////////////////
    // Struct
    ///////////////////

    struct SwapDetail {
        bytes sourceChainSwapPath;
        address[] zetaChainSwapPath;
        bytes targetChainSwapPath;
        uint256 targetChainPoolNum;
        address[] gasZRC20SwapPath;
        bytes recipient;
        bytes sender;
        bytes omnichainSwapContract;
        uint256 minAmountOut;
    }
    ///////////////////
    // State Variables
    ///////////////////
    //TODO: Change it before deployment
    address private constant uniswapRouter =
        0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe;
    address private constant gateWay =
        0xfEDD7A6e3Ef1cC470fbfbF955a22D793dDC0F44E;
    address private constant nativeToken =
        0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf;

    address public kyexTreasury;
    uint32 public maxDeadLine;
    uint16 public crossChainPlatformFee;
    uint16 public sourceChainPlatformFee;
    uint256 public volume;

    ///////////////////
    // Modifiers
    ///////////////////
    modifier onlyGateway() {
        if (msg.sender != address(gateWay)) revert Errors.OnlyGateWay();
        _;
    }

    ///////////////////
    // Initialize Function
    ///////////////////

    /**
     * @notice To Iinitialize contract after deployed.
     */
    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    ///////////////////
    // Public Function
    ///////////////////

    /**
     * @dev Pause contract trading（only owner）
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause contract trading（only owner）
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    ///////////////////
    // External Function
    ///////////////////

    /**
     * @dev update config
     */
    function updateConfig(
        address _kyexTreasury,
        uint32 _maxDeadLine,
        uint16 _crossChainPlatformFee,
        uint16 _sourceChainPlatformFee
    ) external onlyOwner {
        kyexTreasury = _kyexTreasury;
        maxDeadLine = _maxDeadLine;
        crossChainPlatformFee = _crossChainPlatformFee;
        sourceChainPlatformFee = _sourceChainPlatformFee;
    }

    /**
     * @dev Withdraw ZETA from the contract, only the owner can execute this operation
     */
    function withdrawZETA() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.transferNativeToken(owner(), balance);

        emit Events.WithdrawnNativeToken(owner(), balance);
    }

    /**
     * @dev Withdraw ZRC20 from the contract, only the owner can execute this operation
     */
    function withdrawZRC20(address zrc20Address) external onlyOwner {
        uint256 balance = IZRC20(zrc20Address).balanceOf(address(this));
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.safeTransfer(zrc20Address, owner(), balance);

        emit Events.Withdrawn(owner(), zrc20Address, balance);
    }

    function swap(
        uint256 amountIn,
        address tokenIn,
        SwapDetail calldata swapDetail
    ) external payable whenNotPaused nonReentrant {
        receiveToken(amountIn, tokenIn);
        swapExecute(tokenIn, amountIn, swapDetail);
    }

    function onCall(
        MessageContext calldata /*context*/,
        address tokenInOfZetaChain,
        uint256 amountIn,
        bytes calldata message
    ) external override onlyGateway whenNotPaused {
        SwapDetail memory swapDetail = abi.decode(message, (SwapDetail));
        swapExecute(tokenInOfZetaChain, amountIn, swapDetail);
    }

    ///////////////////
    // Internal Function
    ///////////////////
    /**
     * @dev Control upgrade authority
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function swapExecute(
        address tokenInOfZetaChain,
        uint256 amountIn,
        SwapDetail memory swapDetail
    ) private {
        uint256 zetaPathLength = swapDetail.zetaChainSwapPath.length;
        uint256 gasZRC20PathLength = swapDetail.gasZRC20SwapPath.length;
        // uint256 targetChainPoolNum;
        // address targetChainTokenIn;
        // if (swapDetail.targetChainSwapPath.length > 0) {
        //     (targetChainPoolNum, targetChainTokenIn, ) = decodeSwapPath(
        //         swapDetail.targetChainSwapPath
        //     );
        // }
        uint256 gasFee;
        address gasToken;
        if (gasZRC20PathLength > 0) {
            if (swapDetail.targetChainPoolNum == 0) {
                (gasToken, gasFee) = IZRC20(swapDetail.gasZRC20SwapPath[0])
                    .withdrawGasFee();
            } else {
                (gasToken, gasFee) = IZRC20(swapDetail.gasZRC20SwapPath[0])
                    .withdrawGasFeeWithGasLimit(
                        150000 + swapDetail.targetChainPoolNum * 110000
                    );
            }
        }
        address tokenOutOfZetaChain = swapDetail.zetaChainSwapPath[
            zetaPathLength - 1
        ];
        uint256 amountOut;
        if (zetaPathLength == 3 && gasZRC20PathLength == 3) {
            address[] memory uniswapPath = new address[](2);
            uniswapPath[0] = swapDetail.zetaChainSwapPath[0];
            uniswapPath[1] = nativeToken;
            amountOut = uniswapExecute(uniswapPath, amountIn, 0, true);
            uniswapPath[0] = nativeToken;
            uniswapPath[1] = swapDetail.gasZRC20SwapPath[2];
            uint256 amountOutOfGas = uniswapExecute(
                uniswapPath,
                amountOut,
                gasFee,
                false
            );
            uniswapPath[1] = tokenOutOfZetaChain;
            amountOut = uniswapExecute(
                uniswapPath,
                amountOut - amountOutOfGas,
                0,
                true
            );
            TransferHelper.safeApprove(tokenOutOfZetaChain, gateWay, amountOut);
            TransferHelper.safeApprove(gasToken, gateWay, gasFee);
        } else if (gasZRC20PathLength == 1) {
            amountOut = uniswapExecute(
                swapDetail.zetaChainSwapPath,
                amountIn,
                0,
                true
            );
            TransferHelper.safeApprove(tokenOutOfZetaChain, gateWay, amountOut);
            amountOut -= gasFee;
        } else {
            amountOut = uniswapExecute(
                swapDetail.zetaChainSwapPath,
                amountIn,
                0,
                true
            );
        }

        sendToken(
            swapDetail,
            amountOut,
            tokenOutOfZetaChain,
            tokenInOfZetaChain
        );

        emit Events.SwapExecuted(
            msg.sender,
            swapDetail.recipient,
            tokenInOfZetaChain,
            tokenOutOfZetaChain,
            amountIn,
            amountOut
        );
    }

    /**
     * @dev Send platform fees to the treasury
     */
    function sendPlatformFee(
        uint256 amount,
        address token,
        bool isCrossChain
    ) private returns (uint256 newAmount) {
        if (amount == 0) revert Errors.TransferFailed();
        uint256 feeAmount;
        isCrossChain == true
            ? feeAmount = (amount * crossChainPlatformFee) / 10000
            : feeAmount = (amount * sourceChainPlatformFee) / 10000;
        newAmount = amount - feeAmount;

        if (feeAmount > 0) {
            TransferHelper.safeTransfer(token, kyexTreasury, feeAmount);
        }
        emit Events.ReceivePlatformFee(
            token,
            msg.sender,
            kyexTreasury,
            feeAmount
        );
    }

    /**
     * @dev Receive the user's tokens and calculate volume
     */
    function receiveToken(uint256 amountIn, address tokenIn) private {
        if (amountIn == 0) revert Errors.NeedsMoreThanZero();
        uint256 nativeTokenVolume;
        if (tokenIn == nativeToken) {
            if (msg.value != amountIn) revert Errors.IncorrectAmountSent();
            IWETH9(nativeToken).deposit{value: amountIn}();
            nativeTokenVolume = amountIn;
        } else {
            if (IZRC20(tokenIn).allowance(msg.sender, address(this)) < amountIn)
                revert Errors.InsufficientAllowance();

            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );

            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = nativeToken;
            uint256[] memory amount = IUniswapV2Router02(uniswapRouter)
                .getAmountsOut(amountIn, path);

            nativeTokenVolume = amount[1];
        }
        volume += nativeTokenVolume;

        emit Events.ReceivedToken(
            msg.sender,
            tokenIn,
            amountIn,
            nativeTokenVolume
        );
    }

    function sendToken(
        SwapDetail memory swapDetail,
        uint256 amountOut,
        address tokenOutOfZetaChain,
        address tokenInOfZetaChain
    ) private {
        if (swapDetail.targetChainPoolNum > 0) {
            IGatewayZEVM(gateWay).withdrawAndCall(
                swapDetail.omnichainSwapContract,
                amountOut,
                tokenOutOfZetaChain,
                abi.encodeWithSignature(
                    "onReceive(bytes,bytes,uint256,uint256)",
                    swapDetail.targetChainSwapPath,
                    swapDetail.recipient,
                    amountOut,
                    swapDetail.minAmountOut
                ),
                CallOptions(
                    150000 + swapDetail.targetChainPoolNum * 110000,
                    false
                ),
                RevertOptions(
                    address(this),
                    true,
                    address(this),
                    abi.encode(swapDetail.sender, tokenInOfZetaChain),
                    0
                )
            );
        } else if (swapDetail.targetChainSwapPath.length > 0) {
            amountOut = sendPlatformFee(amountOut, tokenOutOfZetaChain, true);
            if (amountOut < swapDetail.minAmountOut)
                revert Errors.SlippageToleranceExceedsMaximum();
            IGatewayZEVM(gateWay).withdraw(
                swapDetail.recipient,
                amountOut,
                tokenOutOfZetaChain,
                RevertOptions(
                    address(this),
                    true,
                    address(this),
                    abi.encode(swapDetail.recipient, tokenInOfZetaChain),
                    0
                )
            );
        } else {
            amountOut = sendPlatformFee(amountOut, tokenOutOfZetaChain, true);
            if (amountOut < swapDetail.minAmountOut)
                revert Errors.SlippageToleranceExceedsMaximum();
            if (tokenOutOfZetaChain == nativeToken) {
                IWETH9(nativeToken).withdraw(amountOut);
                TransferHelper.transferNativeToken(
                    BytesLib.toAddress(swapDetail.recipient, 0),
                    amountOut
                );
            } else {
                TransferHelper.safeTransfer(
                    tokenOutOfZetaChain,
                    BytesLib.toAddress(swapDetail.recipient, 0),
                    amountOut
                );
            }
        }
    }

    function uniswapExecute(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        bool isInput
    ) private returns (uint256) {
        if (path.length == 1) {
            return amountIn;
        }
        TransferHelper.safeApprove(path[0], uniswapRouter, amountIn);
        uint256[] memory amount = new uint256[](path.length);
        if (isInput) {
            amount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                    amountIn,
                    0,
                    path,
                    address(this),
                    block.timestamp + maxDeadLine
                );
            return amount[path.length - 1];
        } else {
            amount = IUniswapV2Router02(uniswapRouter).swapTokensForExactTokens(
                    minAmountOut,
                    amountIn,
                    path,
                    address(this),
                    block.timestamp + maxDeadLine
                );
            return amount[0];
        }
    }

    function onRevert(
        RevertContext calldata revertContext
    ) external onlyGateway {
        uint256 amount = revertContext.amount;
        address inputToken = revertContext.asset;
        (bytes memory sender, address tokenInOfZetaChain) = abi.decode(
            revertContext.revertMessage,
            (bytes, address)
        );
        (address gasZRC20, uint256 gasFee) = IZRC20(tokenInOfZetaChain)
            .withdrawGasFee();
        address[] memory swapPath = new address[](2);
        uint256 amountOut;
        if (gasZRC20 == inputToken) {
            amount -= gasFee;
            swapPath[0] = inputToken;
            swapPath[1] = nativeToken;
            swapPath[2] = tokenInOfZetaChain;
            amountOut = uniswapExecute(swapPath, amount, 0, true);
        } else if (gasZRC20 == tokenInOfZetaChain) {
            swapPath[0] = inputToken;
            swapPath[1] = nativeToken;
            swapPath[2] = tokenInOfZetaChain;
            amountOut = uniswapExecute(swapPath, amount, 0, true);
            amountOut -= gasFee;
        } else {
            swapPath[0] = inputToken;
            swapPath[1] = nativeToken;
            uint256 amountOfZeta = uniswapExecute(swapPath, amount, 0, true);
            swapPath[0] = nativeToken;
            swapPath[1] = gasZRC20;
            uint256 amountOfGas = uniswapExecute(
                swapPath,
                amountOfZeta,
                gasFee,
                false
            );
            swapPath[1] = tokenInOfZetaChain;
            amountOut = uniswapExecute(
                swapPath,
                amountOfZeta - amountOfGas,
                0,
                true
            );
        }
        TransferHelper.safeApprove(tokenInOfZetaChain, gateWay, amountOut);
        IGatewayZEVM(gateWay).withdraw(
            sender,
            amountOut,
            tokenInOfZetaChain,
            RevertOptions(revertContext.sender, false, address(0), "", 0)
        );
    }

    function decodeSwapPath(
        bytes memory path
    )
        private
        pure
        returns (uint256 poolNum, address tokenIn, address tokenOut)
    {
        poolNum = ((path.length - 20) / 23);
        tokenIn = BytesLib.toAddress(path, 0);
        tokenOut = BytesLib.toAddress(path, poolNum * 23);
    }

    ///////////////////
    // receive
    ///////////////////
    receive() external payable {}
}
