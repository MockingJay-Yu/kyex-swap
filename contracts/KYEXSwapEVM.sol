// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "libraries/TransferHelper.sol";
import "libraries/error/Errors.sol";
import "libraries/event/Events.sol";
import "libraries/IWETH.sol";
import "libraries/zetaV2/contracts/evm/interfaces/IGatewayEVM.sol";
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
░╚════╝░╚═╝░░╚═╝░╚════╝░╚═════╝░╚═════╝░░░░░░░░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝、


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

contract KYEXSwapEVM is
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
        address[] gasZRC20SwapPath;
        bytes recipient;
        bytes sender;
        bytes omnichainSwapContract;
        uint256 chainId;
        uint256 minAmountOut;
    }

    ///////////////////
    // State Variables
    ///////////////////
    //TODO: Change it before deployment
    address private constant uniswapRouter =
        0x1b81D678ffb9C0263b24A97847620C99d213eB14;
    address private constant gateWay =
        0x48B9AACC350b20147001f88821d31731Ba4C30ed;
    address private constant universalContract =
        0x88C58f7eD3517d14977Bb841b9A100B1cd090C07;
    address private constant nativeToken =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address public kyexTreasury;
    uint32 public maxDeadLine;
    uint16 public crossChainPlatformFee;
    uint16 public sourceChainPlatformFee;
    uint256 public volume;

    ///////////////////
    // Initialize Function
    ///////////////////

    /**
     * @notice To Iinitialize contract after deployed.
     */
    function initialize() external initializer {
        __Ownable_init(msg.sender);
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
     * @dev Withdraw Native Token from the contract, only the owner can execute this operation
     */
    function withdrawNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.transferNativeToken(owner(), balance);

        emit Events.WithdrawnNativeToken(owner(), balance);
    }

    /**
     * @dev Withdraw ERC20 from the contract, only the owner can execute this operation
     */
    function withdrawERC20(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.safeTransfer(tokenAddress, owner(), balance);

        emit Events.Withdrawn(owner(), tokenAddress, balance);
    }

    function swap(
        uint256 amountIn,
        uint256 nativeTokenVolume,
        SwapDetail calldata swapDetail
    ) external payable whenNotPaused nonReentrant {
        (uint256 poolNum, address tokenIn, address tokenOut) = decodeSwapPath(
            swapDetail.sourceChainSwapPath
        );
        uint256 zetaPathLength = swapDetail.zetaChainSwapPath.length;

        receiveToken(amountIn, tokenIn, nativeTokenVolume);

        address recipient = BytesLib.toAddress(swapDetail.recipient, 0);
        uint256 amountOut;
        if (poolNum > 0) {
            TransferHelper.safeApprove(tokenIn, uniswapRouter, amountIn);
            amountOut = ISwapRouter(uniswapRouter).exactInput(
                ISwapRouter.ExactInputParams(
                    swapDetail.sourceChainSwapPath,
                    address(this),
                    block.timestamp + maxDeadLine,
                    amountIn,
                    0
                )
            );
        } else {
            amountOut = amountIn;
        }
        if (zetaPathLength == 0) {
            amountOut = sendPlatformFee(amountOut, tokenOut, false);
            if (amountOut < swapDetail.minAmountOut)
                revert Errors.SlippageToleranceExceedsMaximum();
            if (tokenOut == nativeToken) {
                IWETH(nativeToken).withdraw(amountOut);
                TransferHelper.transferNativeToken(recipient, amountOut);
            } else {
                TransferHelper.safeTransfer(tokenOut, recipient, amountOut);
            }
        } else {
            bool isDeposit = swapDetail.targetChainSwapPath.length == 0 &&
                zetaPathLength == 1;
            if (isDeposit) {
                amountOut = sendPlatformFee(amountOut, tokenOut, true);
            }
            tokenOut == nativeToken
                ? IWETH(nativeToken).withdraw(amountOut)
                : TransferHelper.safeApprove(tokenOut, gateWay, amountOut);
            if (isDeposit) {
                if (amountOut < swapDetail.minAmountOut)
                    revert Errors.SlippageToleranceExceedsMaximum();
                tokenOut == nativeToken
                    ? IGatewayEVM(gateWay).deposit{value: amountOut}(
                        recipient,
                        RevertOptions(msg.sender, false, msg.sender, "", 21000)
                    )
                    : IGatewayEVM(gateWay).deposit(
                        recipient,
                        RevertOptions(msg.sender, false, msg.sender, "", 21000)
                    );
            } else {
                tokenOut == nativeToken
                    ? IGatewayEVM(gateWay).depositAndCall{value: amountOut}(
                        universalContract,
                        abi.encode(swapDetail),
                        RevertOptions(msg.sender, false, msg.sender, "", 21000)
                    )
                    : IGatewayEVM(gateWay).depositAndCall(
                        universalContract,
                        amountOut,
                        tokenOut,
                        abi.encode(swapDetail),
                        RevertOptions(msg.sender, false, msg.sender, "", 21000)
                    );
            }
        }
        emit Events.SwapExecuted(
            msg.sender,
            swapDetail.recipient,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        );
    }

    function onReceive(
        bytes calldata targetChainSwapPath,
        bytes calldata recipient,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable whenNotPaused nonReentrant {
        (, address tokenIn, address tokenOut) = decodeSwapPath(
            targetChainSwapPath
        );
        if (tokenIn == nativeToken) {
            if (msg.value != amountIn) revert Errors.IncorrectAmountSent();
            IWETH(nativeToken).deposit{value: amountIn}();
        } else {
            if (IERC20(tokenIn).balanceOf(address(this)) < amountIn)
                revert Errors.IncorrectAmountSent();
        }
        TransferHelper.safeApprove(tokenIn, uniswapRouter, amountIn);
        uint256 amountOut = ISwapRouter(uniswapRouter).exactInput(
            ISwapRouter.ExactInputParams(
                targetChainSwapPath,
                address(this),
                block.timestamp + maxDeadLine,
                amountIn,
                0
            )
        );
        amountOut = sendPlatformFee(amountOut, tokenOut, true);
        if (amountOut < minAmountOut)
            revert Errors.SlippageToleranceExceedsMaximum();
        if (tokenOut == nativeToken) {
            IWETH(nativeToken).withdraw(amountOut);
            TransferHelper.transferNativeToken(
                BytesLib.toAddress(recipient, 0),
                amountOut
            );
        } else {
            TransferHelper.safeTransfer(
                tokenOut,
                BytesLib.toAddress(recipient, 0),
                amountOut
            );
        }
    }

    /**
     * @dev Control upgrade authority
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev Receive the user's tokens and calculate volume
     */
    function receiveToken(
        uint256 amountIn,
        address tokenIn,
        uint256 nativeTokenVolume
    ) private {
        if (amountIn == 0) revert Errors.NeedsMoreThanZero();

        if (tokenIn == nativeToken) {
            if (msg.value != amountIn) revert Errors.IncorrectAmountSent();
            IWETH(nativeToken).deposit{value: amountIn}();
            volume += nativeTokenVolume;
        } else {
            if (IERC20(tokenIn).allowance(msg.sender, address(this)) < amountIn)
                revert Errors.InsufficientAllowance();

            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
            volume += nativeTokenVolume;
        }
        emit Events.ReceivedToken(
            msg.sender,
            tokenIn,
            amountIn,
            nativeTokenVolume
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
