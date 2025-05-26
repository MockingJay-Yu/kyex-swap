// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Errors {
    error SwapFailed();
    error ApprovalFailed();
    error TransferFailed();
    error InsufficientFunds();
    error InsufficientGasForWithdraw();
    error NeedsMoreThanZero();
    error OnlyGateWay();
    error ZETANotSupported();
    error InsufficientAllowance();
    error SlippageToleranceExceedsMaximum();
    error PlatformFeeNeedslessThanOneHundredPercent();
    error IncorrectAmountSent();
    error ErrorTransferringZeta();
    error OnlyTreasury();
    error ExceedCurrentTimestamp();
    error InvalidZetaValueAndGas();
    error CancelAmountMoreThanAmountIn();
    error ExpiryEarlier();
    error CallSquidRouterFail();
    error OnlySenderOrOwner();
    error NotEnoughRemainingAmount();
    error NotEnoughRemainingExecuteCount();
    error GasFeeMismatch();
    error OrderNotExist();
    error InvalidPlatformFee();
    error InvalidParameter();
}
