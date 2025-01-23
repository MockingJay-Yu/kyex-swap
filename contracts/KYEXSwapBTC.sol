// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/IWZETA.sol";
import "libraries/zetaV2/contracts/zevm/interfaces/IZRC20.sol";
import "libraries/zetaV2/contracts/SystemContract.sol";
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

contract KYEXSwapBTC is
    zContract,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    ///////////////////
    // State Variables
    ///////////////////
    //TODO: Change it before deployment
    address private constant uniswapRouter =
        0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe;
    address private constant systemContract =
        0x91d18e54DAf4F677cB28167158d6dd21F6aB3921;
    address private constant nativeToken =
        0x5F0b1a82749cb4E2278EC87F8BF6B618dC71a8bf;
    address private constant btcAddress =
        0x13A0c5930C028511Dc02665E7285134B6d11A5f4;

    address public kyexTreasury;
    uint32 public maxDeadLine;
    uint16 public crossChainPlatformFee;
    uint16 public sourceChainPlatformFee;
    uint256 public volume;

    ///////////////////
    // Modifiers
    ///////////////////
    modifier onlySystemContract() {
        if (msg.sender != address(systemContract)) revert Errors.OnlyGateWay();
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

    function onCrossChainCall(
        zContext calldata /*context*/,
        address /*tokenInOfZetaChain*/,
        uint256 amountIn,
        bytes calldata message
    ) external override onlySystemContract whenNotPaused {
        address targetToken = bytesToAddress(message, 0);
        bytes memory recipient = abi.encodePacked(bytesToAddress(message, 20));
        swapExecute(amountIn, targetToken, recipient);
    }

    ///////////////////
    // Internal Function
    ///////////////////
    /**
     * @dev Control upgrade authority
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function swapExecute(
        uint256 amountIn,
        address targetToken,
        bytes memory recipient
    ) private {
        uint256 amountOut;
        (address gasToken, uint256 gasFee) = IZRC20(targetToken)
            .withdrawGasFee();
        if (gasToken != targetToken) {
            address[] memory uniswapPath = new address[](2);
            uniswapPath[0] = btcAddress;
            uniswapPath[1] = nativeToken;
            amountOut = uniswapExecute(uniswapPath, amountIn, 0, true);
            uniswapPath[0] = nativeToken;
            uniswapPath[1] = gasToken;
            uint256 amountOutOfGas = uniswapExecute(
                uniswapPath,
                amountOut,
                gasFee,
                false
            );
            uniswapPath[1] = targetToken;
            amountOut = uniswapExecute(
                uniswapPath,
                amountOut - amountOutOfGas,
                0,
                true
            );
            TransferHelper.safeApprove(gasToken, targetToken, gasFee);
        } else {
            address[] memory uniswapPath = new address[](3);
            uniswapPath[0] = btcAddress;
            uniswapPath[1] = nativeToken;
            uniswapPath[2] = targetToken;
            amountOut = uniswapExecute(uniswapPath, amountIn, 0, true);
            amountOut -= gasFee;
        }

        sendToken(targetToken, recipient, amountOut);

        emit Events.SwapExecuted(
            msg.sender,
            recipient,
            btcAddress,
            targetToken,
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

    function sendToken(
        address targetToken,
        bytes memory recipient,
        uint256 amountOut
    ) private {
        amountOut = sendPlatformFee(amountOut, targetToken, true);
        IZRC20(targetToken).withdraw(recipient, amountOut);
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

    function bytesToAddress(
        bytes calldata data,
        uint256 offset
    ) internal pure returns (address output) {
        bytes memory b = data[offset:offset + 20];
        assembly {
            output := mload(add(b, 20))
        }
    }

    ///////////////////
    // receive
    ///////////////////
    receive() external payable {}
}
