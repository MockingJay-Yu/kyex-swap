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
        bytes toToken;
        address sender;
        bytes recipient;
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
        bytes toToken;
        bytes recipient;
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
    ) external payable whenNotPaused {
        if (
            params.fromToken == address(0) ||
            params.fromChainId == 0 ||
            params.amountIn == 0 ||
            params.toChainId == 0 ||
            params.toToken.length == 0 ||
            params.recipient.length == 0 ||
            params.executeCount == 0 ||
            params.timeInterval == 0
        ) revert Errors.InvalidParameter();
        receivedToken(
            params.amountIn,
            params.gasFee,
            params.fromToken,
            params.executeCount
        );
        addOrder(params, currentOrderId);
        emit OpenOrder(currentOrderId, msg.sender);
        currentOrderId++;
    }

    function executeOrder(
        uint256 orderId,
        uint256 excuteAmount,
        address target,
        uint256 gasLimit,
        uint256 nativeTokenVolume,
        bytes calldata data
    ) external onlyOwner whenNotPaused existsOrder(orderId) {
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
        if (
            order.fromToken ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            (success, ) = target.call{
                gas: gasLimit,
                value: sendAmount + order.gasFee
            }(data);
        } else {
            TransferHelper.safeApprove(order.fromToken, target, sendAmount);
            (success, ) = target.call{gas: gasLimit, value: order.gasFee}(data);
        }
        if (!success) revert Errors.CallSquidRouterFail();
        if (order.remainingAmount - excuteAmount == 0) {
            orderIds.remove(orderId);
            delete orders[orderId];
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

    function cancelOrder(
        uint256 orderId
    ) external whenNotPaused existsOrder(orderId) {
        DCAOrder storage order = orders[orderId];
        if (msg.sender != owner() && order.sender != msg.sender)
            revert Errors.OnlySenderOrOwner();
        if (
            order.fromToken ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            TransferHelper.transferNativeToken(
                order.sender,
                order.remainingAmount +
                    order.gasFee *
                    order.remainingExecuteCount
            );
        } else {
            TransferHelper.safeTransfer(
                order.fromToken,
                order.sender,
                orders[orderId].remainingAmount
            );
            TransferHelper.transferNativeToken(
                order.sender,
                order.gasFee * order.remainingExecuteCount
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
        if (tokenIn != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
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
        emit ReceivedToken(msg.sender, tokenIn, amountIn, gasFee);
    }
}
