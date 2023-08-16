// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/tokens/ERC20/IERC20.sol";
import "./interfaces/IPair.sol";

contract Flashloaner {
    uint256 expectedLoanAmount;

    function flashloan(
        address pairAddress,
        uint256 amount0Out,
        uint256 amount1Out,
        address tokenAddress
    ) external {
        if (amount0Out > 0) expectedLoanAmount = amount0Out;
        if (amount1Out > 0) expectedLoanAmount = amount1Out;

        IPair(pairAddress).swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(tokenAddress)
        );
    }

    function swapCall(
        address pairAddress,
        uint amount0Out,
        uint amount1Out,
        bytes calldata data
    ) external {
        address tokenAddress = abi.decode(data, (address));
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > expectedLoanAmount, "InsufficientFlashLoanAmount");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer", pairAddress, expectedLoanAmount)
        );
        require(success, "transfer failed");
    }
}
