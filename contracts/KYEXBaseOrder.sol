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
    address public treasury;

    /////////////////////
    /// Modifiers
    ////////////////////
    modifier existsOrder(uint256 orderId) {
        if (!orderIds.contains(orderId)) revert Errors.OrderNotExist();
        _;
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
    event ReceivedToken(
        address indexed sender,
        address indexed token,
        uint256 amountIn,
        uint256 gasFee
    );
    event ReceivePlatformFee(
        address indexed token,
        address indexed sender,
        address receiver,
        uint256 amount
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

    /**
     * @notice To Iinitialize contract after deployed.
     */
    function initialize(
        uint256 _platformFee,
        address _treasury
    ) external initializer {
        if (_platformFee >= 10000) revert Errors.InvalidPlatformFee();

        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
        platformFee = _platformFee;
        treasury = _treasury;
    }

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

    function updateTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    ///////////////////
    // Internal Function
    ///////////////////
    function deductPlatformFee(
        uint256 amoutIn,
        address tokenIn,
        address sender
    ) internal returns (uint256) {
        uint256 feeAmount = (amoutIn * platformFee) / 10000;

        tokenIn == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
            ? TransferHelper.transferNativeToken(treasury, feeAmount)
            : TransferHelper.safeTransfer(tokenIn, treasury, feeAmount);
        emit ReceivePlatformFee(tokenIn, sender, treasury, feeAmount);
        return amoutIn - feeAmount;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    ///////////////////
    // receive
    ///////////////////
    receive() external payable {}
}
