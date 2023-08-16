// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

interface IFactory {
    error Forbidden();
    error PairExist();
    error ZeroAddress();
    error IdenticalAddress();

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint length
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function pairs(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    // function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}
