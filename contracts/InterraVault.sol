// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "libraries/error/Errors.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "libraries/TransferHelper.sol";

contract InterraVault is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event SendFunds(address sender, uint256 sendAmount, uint256 gasFee);

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice To Iinitialize contract after deployed.
     */
    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    function sendFunds(
        address target,
        uint256 gasLimit,
        bytes calldata data,
        uint256 sendAmount,
        uint256 gasFee
    ) external whenNotPaused onlyOwner nonReentrant {
        if (
            target == address(0) ||
            gasLimit == 0 ||
            data.length == 0 ||
            sendAmount == 0 ||
            gasFee == 0
        ) revert Errors.InvalidParameter();
        uint256 _value = sendAmount + gasFee;
        if (_value > address(this).balance) revert Errors.InsufficientFunds();
        (bool success, ) = target.call{gas: gasLimit, value: _value}(data);

        if (!success) revert Errors.CallSquidRouterFail();

        emit SendFunds(msg.sender, sendAmount, gasFee);
    }

    function withdrawNativeToken() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.InsufficientFunds();
        TransferHelper.transferNativeToken(owner(), balance);
    }

    receive() external payable {}
}
