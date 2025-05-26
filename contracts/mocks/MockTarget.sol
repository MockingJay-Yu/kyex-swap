// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

contract MockTarget {
    event MockCalled(address sender, uint256 value);

    function fail() external payable {
        revert("MockTarget: Forced failure");
    }

    function call() external payable {
        emit MockCalled(msg.sender, msg.value);
    }
}
