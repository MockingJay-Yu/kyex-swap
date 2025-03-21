// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "libraries/error/Errors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "libraries/IWETH.sol";
import "libraries/TransferHelper.sol";
import "libraries/IWETH.sol";
import "libraries/error/Errors.sol";

contract KYEXSwapLimit02 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    /////////////////////
    /// struct
    ////////////////////
    struct Order {
        address fromToken;
        uint256 fromChainId;
        uint256 amountIn;
        uint256 toChainId;
        address toToken;
        address recipient;
        uint256 amountOut;
        uint256 amountOutMin;
        uint256 expiry;
        address sender;
    }

    struct DCAOrder {
        address fromToken;
        uint256 fromChainId;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 amountOutMax;
        uint256 toChainId;
        address toToken;
        address recipient;
        uint16 executeCount;
        uint256 timeInterval;
    }

    struct cancelOrdersParam {
        uint256 orderId;
        uint256 cancelAmount;
    }

    /////////////////////
    /// State variable
    ////////////////////
    uint256 public currentOrderId;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => DCAOrder) public DCAOrders;
    EnumerableSet.UintSet private orderIds;
    mapping(uint256 => address) public nativeTokens;

    /////////////////////
    /// Event
    ////////////////////

    event OpenOrder(uint256 indexed orderId, address indexed sender);
    event OpenDCAOrder(uint256 indexed orderId, address indexed sender);
    event ExcuteOrder(uint256[] orderIds);
    event CancelOrder(uint256 indexed orderId);

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

    function updateNativeToken(
        uint256 chainId,
        address nativeToken
    ) external onlyOwner {
        nativeTokens[chainId] = nativeToken;
    }

    function openOrder(
        Order memory _order
    ) external payable whenNotPaused nonReentrant {
        _order.fromToken = receiveToken(_order.amountIn, _order.fromToken);
        uint256 orderId = currentOrderId;
        orders[orderId] = _order;
        orderIds.add(orderId);
        emit OpenOrder(orderId, msg.sender);
        currentOrderId++;
    }

    function openDCAOrder(
        DCAOrder memory _DCAOrder
    ) external payable whenNotPaused nonReentrant {
        _DCAOrder.fromToken = receiveToken(
            _DCAOrder.amountIn,
            _DCAOrder.fromToken
        );
        uint256 orderId = currentOrderId;
        DCAOrders[orderId] = _DCAOrder;
        orderIds.add(orderId);
        emit OpenDCAOrder(orderId, msg.sender);
        currentOrderId++;
    }

    function getAllTokenId() external view returns (uint256[] memory) {
        return orderIds.values();
    }

    function excuteOrder(uint256[] calldata _orderIds) external onlyOwner {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            delete orders[_orderIds[i]];
        }
        emit ExcuteOrder(_orderIds);
    }

    function cancelOrder(
        uint256 _orderId,
        uint256 _cancelAmount
    ) public payable onlyOwner {
        address sender = orders[_orderId].sender;
        address fromToken = orders[_orderId].fromToken;
        uint256 amountIn = orders[_orderId].amountIn;
        if (_cancelAmount > amountIn)
            revert Errors.CancelAmountMoreThanAmountIn();

        if (fromToken == nativeTokens[block.chainid]) {
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                address(this),
                _cancelAmount
            );
            IWETH(fromToken).withdraw(_cancelAmount);
            TransferHelper.transferNativeToken(sender, _cancelAmount);
        } else {
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                sender,
                _cancelAmount
            );
        }
        orderIds.remove(_orderId);
        delete orders[_orderId];
        emit CancelOrder(_orderId);
    }

    function cancelOrders(
        cancelOrdersParam[] calldata _cancelOrders
    ) external payable onlyOwner {
        for (uint16 i = 0; i < _cancelOrders.length; i++) {
            cancelOrder(
                _cancelOrders[i].orderId,
                _cancelOrders[i].cancelAmount
            );
        }
    }

    /* @dev Receive the user's tokens and calculate volume*/
    function receiveToken(
        uint256 amountIn,
        address tokenIn
    ) private returns (address) {
        if (amountIn == 0) revert Errors.NeedsMoreThanZero();

        if (msg.value == 0) {
            if (IERC20(tokenIn).allowance(msg.sender, address(this)) < amountIn)
                revert Errors.InsufficientAllowance();
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                owner(),
                amountIn
            );
        } else {
            if (msg.value != amountIn) revert Errors.IncorrectAmountSent();
            tokenIn = nativeTokens[block.chainid];
            IWETH(tokenIn).deposit{value: amountIn}();
            TransferHelper.safeTransfer(tokenIn, owner(), amountIn);
        }
        return tokenIn;
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

    function _authorizeUpgrade(address) internal virtual override {}

    receive() external payable {}
}
