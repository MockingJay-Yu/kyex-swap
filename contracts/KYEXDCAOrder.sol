// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./KYEXBaseOrder.sol";

contract KYEXDCAOrder is KYEXBaseOrder {
    using EnumerableSet for EnumerableSet.UintSet;

    struct DCAOrder {
        address fromToken;
        uint256 fromChainId;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 amountOutMax;
        uint256 toChainId;
        address toToken;
        address sender;
        address recipient;
        uint16 executeCount;
        uint256 timeInterval;
        uint256 remainingExecuteCount;
        uint256 remainingAmount;
        uint256 gasFee;
    }

    struct OpenOrderParams {
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
        uint256 gasFee;
    }

    mapping(uint256 => DCAOrder) private orders;

    /////////////////////
    /// External Function
    ////////////////////

    function getOrder(uint256 orderId) external view returns (DCAOrder memory) {
        return orders[orderId];
    }

    function openOrder(
        OpenOrderParams calldata params
    ) external payable whenNotPaused returns (uint256 orderId) {
        receivedToken(
            params.amountIn,
            params.gasFee,
            params.fromToken,
            params.executeCount
        );

        orderId = currentOrderId;
        addOrder(params, orderId);
        emit OpenOrder(orderId, msg.sender);
        currentOrderId++;
    }

    function excuteOrder(
        uint256 orderId,
        uint256 excuteAmount,
        address target,
        uint256 gasLimit,
        uint256 nativeTokenVolume,
        bytes calldata data
    ) external onlyOwner {
        DCAOrder storage order = orders[orderId];

        if (order.remainingAmount < excuteAmount)
            revert Errors.NotEnoughRemainingAmount();
        if (order.remainingExecuteCount == 0)
            revert Errors.NotEnoughRemainingExecuteCount();

        uint256 sendAmount = deductPlatformFee(
            excuteAmount,
            order.fromToken,
            order.sender
        );
        if (sendAmount == 0) revert Errors.NeedsMoreThanZero();
        bool success;
        if (order.fromToken == address(0)) {
            (success, ) = target.call{gas: gasLimit, value: sendAmount}(data);
        } else {
            TransferHelper.safeApprove(order.fromToken, target, sendAmount);
            (success, ) = target.call{gas: gasLimit}(data);
        }
        if (!success) revert Errors.CallSquidRouterFail();
        if (order.remainingAmount - excuteAmount == 0) {
            orderIds.remove(orderId);
            delete orders[orderId];
            emit DeleteOrder(orderId, msg.sender);
        } else {
            order.remainingExecuteCount -= 1;
            order.remainingAmount -= excuteAmount;
        }
        emit ExcutedOrder(
            orderId,
            order.fromToken,
            sendAmount,
            nativeTokenVolume
        );
    }

    function cancelOrder(uint256 orderId) external {
        address sender = orders[orderId].sender;
        if (msg.sender != owner() && sender != msg.sender)
            revert Errors.OnlySender();
        address fromToken = orders[orderId].fromToken;
        if (fromToken == address(0)) {
            TransferHelper.transferNativeToken(
                sender,
                orders[orderId].remainingAmount
            );
        } else {
            TransferHelper.safeTransferFrom(
                fromToken,
                address(this),
                sender,
                orders[orderId].remainingAmount
            );
        }

        orderIds.remove(orderId);
        delete orders[orderId];
        emit CancelOrder(orderId, msg.sender);
    }

    function addOrder(
        OpenOrderParams calldata params,
        uint256 orderId
    ) private {
        orders[orderId] = DCAOrder(
            params.fromToken,
            params.fromChainId,
            params.amountIn,
            params.amountOutMin,
            params.amountOutMax,
            params.toChainId,
            params.toToken,
            msg.sender,
            params.recipient,
            params.executeCount,
            params.timeInterval,
            params.executeCount,
            params.amountIn,
            params.gasFee
        );
        orderIds.add(orderId);
    }

    function receivedToken(
        uint256 amountIn,
        uint256 gasFee,
        address tokenIn,
        uint256 executeCount
    ) private {
        if (amountIn == 0) revert Errors.NeedsMoreThanZero();
        if (tokenIn != address(0)) {
            if (gasFee * executeCount > msg.value)
                revert Errors.InsufficientFunds();

            if (IERC20(tokenIn).allowance(msg.sender, address(this)) < amountIn)
                revert Errors.InsufficientAllowance();
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountIn
            );
        } else {
            if (amountIn + gasFee * executeCount > msg.value)
                revert Errors.InsufficientFunds();
        }
        emit Events.ReceivedToken(msg.sender, tokenIn, amountIn, gasFee);
    }
}
