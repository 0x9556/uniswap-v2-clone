// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

interface ISwapCallee {
    function swapCall(address, uint256, uint256, bytes calldata) external;
}
