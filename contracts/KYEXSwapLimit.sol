// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "libraries/error/Errors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "libraries/IWETH.sol";
import "libraries/TransferHelper.sol";
import "libraries/IWETH.sol";

contract KYEXSwapLimit {
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

    /////////////////////
    /// State variable
    ////////////////////
    uint256 public currentOrderId;
    mapping(uint256 => Order) public orders;
    EnumerableSet.UintSet private orderIds;
    mapping(uint256 => address) public nativeTokens;

    address private treasuryAddr = 0x4e8A3Ff8daD9Fa3BCaCF9f282E4bd1BD3ef865dD;

    ///////////////////
    // Modifiers
    ///////////////////
    modifier onlyTreasury() {
        if (msg.sender != treasuryAddr) revert Errors.OnlyTreasury();
        _;
    }
    /////////////////////
    /// Event
    ////////////////////

    event OpenOrder(uint256 indexed orderId, address indexed sender);
    event ExcuteOrder(uint256[] orderIds);
    event CancelOrder(uint256 indexed orderId);

    function updateNativeToken(
        uint256 chainId,
        address nativeToken
    ) external onlyTreasury {
        nativeTokens[chainId] = nativeToken;
    }

    function updateTreasuryAddr(address _treasuryAddr) external onlyTreasury {
        treasuryAddr = _treasuryAddr;
    }

    function openOrder(
        address _fromToken,
        uint256 _amountIn,
        uint256 _toChainId,
        address _toToken,
        address _recipient,
        uint256 _amountOut,
        uint256 _amountOutMin,
        uint256 _expiry
    ) external payable {
        address fromToken = receiveToken(_amountIn, _fromToken);
        Order memory order = Order({
            fromToken: fromToken,
            fromChainId: block.chainid,
            amountIn: _amountIn,
            toChainId: _toChainId,
            toToken: _toToken,
            recipient: _recipient,
            amountOut: _amountOut,
            amountOutMin: _amountOutMin,
            expiry: _expiry,
            sender: msg.sender
        });
        uint256 orderId = currentOrderId++;
        orderIds.add(orderId);
        orders[orderId] = order;
        emit OpenOrder(orderId, msg.sender);
    }

    function getAllTokenId() external view returns (uint256[] memory) {
        return orderIds.values();
    }

    function excuteOrder(uint256[] calldata _orderIds) external onlyTreasury {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            delete orders[_orderIds[i]];
        }
        emit ExcuteOrder(_orderIds);
    }

    function cancelOrder(uint256 _orderId) external payable onlyTreasury {
        address sender = orders[_orderId].sender;
        uint256 amountIn = orders[_orderId].amountIn;
        address fromToken = orders[_orderId].fromToken;
        if (IERC20(fromToken).allowance(msg.sender, address(this)) < amountIn)
            revert Errors.InsufficientAllowance();
        if (fromToken == nativeTokens[block.chainid]) {
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                address(this),
                amountIn
            );
            IWETH(fromToken).withdraw(amountIn);
            TransferHelper.transferNativeToken(sender, amountIn);
        } else {
            TransferHelper.safeTransferFrom(
                fromToken,
                msg.sender,
                sender,
                amountIn
            );
        }
        orderIds.remove(_orderId);
        delete orders[_orderId];
        emit CancelOrder(_orderId);
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
                treasuryAddr,
                amountIn
            );
        } else {
            if (msg.value != amountIn) revert Errors.IncorrectAmountSent();
            tokenIn = nativeTokens[block.chainid];
            IWETH(tokenIn).deposit{value: amountIn}();
            TransferHelper.safeTransfer(tokenIn, treasuryAddr, amountIn);
        }
        return tokenIn;
    }

    /**
     * @dev Withdraw Native Token from the contract, only the owner can execute this operation
     */
    function withdrawNativeToken() external onlyTreasury {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.transferNativeToken(treasuryAddr, balance);
    }

    /**
     * @dev Withdraw ERC20 from the contract, only the owner can execute this operation
     */
    function withdrawERC20(address tokenAddress) external onlyTreasury {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.safeTransfer(tokenAddress, treasuryAddr, balance);
    }

    receive() external payable {}
}
