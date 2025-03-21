// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "libraries/TransferHelper.sol";
import "libraries/error/Errors.sol";
import "libraries/event/Events.sol";

abstract contract KYEXBaseOrder is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    /////////////////////
    /// State variable
    ////////////////////
    uint256 public currentOrderId;
    EnumerableSet.UintSet internal orderIds;
    uint256 public platformFee;

    /**
     * @notice To Iinitialize contract after deployed.
     */
    function initialize(uint256 _platformFee) external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        platformFee = _platformFee;
    }

    /////////////////////
    /// Event
    ////////////////////
    event OpenOrder(uint256 indexed orderId, address indexed sender);
    event ExcutedOrder(
        uint256 indexed orderId,
        address indexed fromToken,
        uint256 indexed sendAmount,
        uint256 nativeTokenVolume
    );
    event CancelOrder(uint256 indexed orderId, address indexed sender);
    event DeleteOrder(uint256 indexed orderId, address indexed sender);
    event ReceivedToken(
        address indexed sender,
        address indexed token,
        uint256 amountIn,
        uint256 gasFee
    );

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
    function getAllTokenId() external view returns (uint256[] memory) {
        return orderIds.values();
    }

    /**
     * @dev Withdraw Native Token from the contract, only the owner can execute this operation
     */
    function withdrawNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.transferNativeToken(owner(), balance);
    }

    /**
     * @dev Withdraw ERC20 from the contract, only the owner can execute this operation
     */
    function withdrawERC20(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.safeTransfer(tokenAddress, owner(), balance);
    }

    function updatePlatformFee(uint256 newPlatformFee) external onlyOwner {
        platformFee = newPlatformFee;
    }

    ///////////////////
    // Internal Function
    ///////////////////
    function receiveToken(
        uint256 amountIn,
        uint256 gasFee,
        address tokenIn
    ) internal {
        if (amountIn == 0) revert Errors.NeedsMoreThanZero();
        if (tokenIn != address(0)) {
            if (gasFee > msg.value) revert Errors.InsufficientFunds();
            if (IERC20(tokenIn).allowance(msg.sender, address(this)) < amountIn)
                revert Errors.InsufficientAllowance();
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
        } else {
            if (amountIn + gasFee > msg.value)
                revert Errors.InsufficientFunds();
        }
        emit ReceivedToken(msg.sender, tokenIn, amountIn, gasFee);
    }

    function deductPlatformFee(
        uint256 amoutIn,
        address tokenIn,
        address sender
    ) internal returns (uint256) {
        uint256 feeAmount = (amoutIn * platformFee) / 10000;
        if (tokenIn != address(0)) {
            TransferHelper.safeTransfer(tokenIn, owner(), feeAmount);
        }
        emit Events.ReceivePlatformFee(tokenIn, sender, owner(), feeAmount);
        return amoutIn - feeAmount;
    }

    function _authorizeUpgrade(address) internal virtual override {}

    ///////////////////
    // receive
    ///////////////////
    receive() external payable {}
}
