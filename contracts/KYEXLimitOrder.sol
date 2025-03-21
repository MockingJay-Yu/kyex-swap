// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KYEXBaseOrder.sol";

contract KYEXLimitOrder is KYEXBaseOrder {
    using EnumerableSet for EnumerableSet.UintSet;

    struct LimitOrder {
        address fromToken;
        uint256 fromChainId;
        uint256 amountIn;
        uint256 toChainId;
        address toToken;
        address recipient;
        address sender;
        uint256 expiry;
        uint256 amountOut;
        uint256 gasFee;
    }

    struct OpenOrderParams {
        address fromToken;
        uint256 fromChainId;
        uint256 amountIn;
        uint256 toChainId;
        address toToken;
        address recipient;
        uint256 expiry;
        uint256 amountOut;
        uint256 gasFee;
    }

    mapping(uint256 => LimitOrder) public orders;

    /////////////////////
    /// External Function
    ////////////////////
    function openOrder(
        OpenOrderParams calldata params
    ) external payable whenNotPaused returns (uint256 orderId) {
        receiveToken(params.amountIn, params.gasFee, params.fromToken);
        if (params.expiry <= block.timestamp) revert Errors.ExpiryEarlier();

        orderId = currentOrderId;
        addOrder(params, orderId);
        emit OpenOrder(orderId, msg.sender);
        currentOrderId++;
    }

    function excuteOrder(
        uint256 orderId,
        address target,
        uint256 gasLimit,
        uint256 nativeTokenVolume,
        bytes calldata data
    ) external onlyOwner {
        LimitOrder memory order = orders[orderId];
        if (orders[orderId].expiry < block.timestamp)
            revert Errors.ExpiryEarlier();
        uint256 sendAmount = deductPlatformFee(
            order.amountIn,
            order.fromToken,
            order.sender
        );
        if (sendAmount == 0) revert Errors.NeedsMoreThanZero();
        bool success;
        if (order.fromToken == address(0)) {
            (success, ) = target.call{gas: gasLimit, value: sendAmount}(data);
        } else {
            TransferHelper.safeApprove(order.fromToken, target, sendAmount);
            (success, ) = target.call{gas: gasLimit, value: order.gasFee}(data);
        }
        if (!success) revert Errors.CallSquidRouterFail();
        emit ExcutedOrder(
            orderId,
            order.fromToken,
            sendAmount,
            nativeTokenVolume
        );
        orderIds.remove(orderId);
        delete orders[orderId];
        emit DeleteOrder(orderId, msg.sender);
    }

    function cancelOrder(uint256 orderId) external {
        address sender = orders[orderId].sender;
        if (msg.sender != owner() && sender != msg.sender)
            revert Errors.OnlySender();
        address fromToken = orders[orderId].fromToken;
        uint256 amountIn = orders[orderId].amountIn;
        uint256 gasFee = orders[orderId].gasFee;
        if (fromToken == address(0)) {
            TransferHelper.transferNativeToken(sender, amountIn + gasFee);
        } else {
            TransferHelper.safeTransferFrom(
                fromToken,
                address(this),
                sender,
                amountIn
            );
            TransferHelper.transferNativeToken(sender, gasFee);
        }
        orderIds.remove(orderId);
        delete orders[orderId];
        emit CancelOrder(orderId, msg.sender);
    }

    function addOrder(
        OpenOrderParams calldata params,
        uint256 orderId
    ) private {
        orders[orderId] = LimitOrder(
            params.fromToken,
            params.fromChainId,
            params.amountIn,
            params.toChainId,
            params.toToken,
            params.recipient,
            msg.sender,
            params.expiry,
            params.amountOut,
            params.gasFee
        );
        orderIds.add(orderId);
    }
}
