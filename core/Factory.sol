// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./Pair.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";

contract Factory is IFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    constructor(address _feeTosetter) {
        feeToSetter = _feeTosetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddress();

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();
        if (pairs[token0][token1] != address(0)) revert PairExist();

        bytes memory bytecode = type(Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;

        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert Forbidden();
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert Forbidden();
        feeToSetter = _feeToSetter;
    }
}
