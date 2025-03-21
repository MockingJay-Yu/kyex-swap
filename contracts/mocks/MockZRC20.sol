// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockZRC20 is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * (10 ** uint256(decimals())));
    }

    function withdrawGasFee() external view returns (address, uint256) {
        return (address(this), 210000 * 10 ** 9);
    }

    function withdrawGasFeeWithGasLimit(
        uint256 gasLimit
    ) external view returns (address, uint256) {
        uint256 gasFee = gasLimit * 10 ** 9;
        return (address(this), gasFee);
    }
}
