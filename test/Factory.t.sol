// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../core/Factory.sol";

contract FactoryTest is Test {
    Factory factory;

    function setUp() public {
        factory = new Factory(msg.sender);
    }

    function test_feeTo_feeToSetter_allPairsLength() public {
        assertEq(factory.feeTo(), address(0));
        assertEq(factory.feeToSetter(), msg.sender);
        assertEq(factory.allPairsLength(), 0);
    }
}
