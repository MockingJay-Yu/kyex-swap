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
        bytes toToken; // address for EVM / bytes32 for Solana
        bytes recipient;
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
        bytes toToken;
        bytes recipient;
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
    ) external payable whenNotPaused {
        if (
            params.fromToken == address(0) ||
            params.fromChainId == 0 ||
            params.amountIn == 0 ||
            params.toChainId == 0 ||
            params.toToken.length == 0 ||
            params.recipient.length == 0
        ) revert Errors.InvalidParameter();
        if (params.expiry <= block.timestamp) revert Errors.ExpiryEarlier();
        receiveToken(params.amountIn, params.gasFee, params.fromToken);

        addOrder(params, currentOrderId);
        emit OpenOrder(currentOrderId, msg.sender);
        currentOrderId++;
    }

    function executeOrder(
        uint256 orderId,
        address target,
        uint256 gasLimit,
        uint256 nativeTokenVolume,
        bytes calldata data
    ) external onlyOwner whenNotPaused existsOrder(orderId) {
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
        orderIds.remove(orderId);
        delete orders[orderId];
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
        address sender = orders[orderId].sender;
        if (msg.sender != owner() && sender != msg.sender)
            revert Errors.OnlySenderOrOwner();
        address fromToken = orders[orderId].fromToken;
        uint256 amountIn = orders[orderId].amountIn;
        uint256 gasFee = orders[orderId].gasFee;
        if (fromToken == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            TransferHelper.transferNativeToken(sender, amountIn + gasFee);
        } else {
            TransferHelper.safeTransfer(fromToken, sender, amountIn);
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

    function receiveToken(
        uint256 amountIn,
        uint256 gasFee,
        address tokenIn
    ) private {
        if (tokenIn != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
            if (gasFee != msg.value) revert Errors.GasFeeMismatch();
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
}
