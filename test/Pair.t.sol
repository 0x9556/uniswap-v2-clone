// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../core/Pair.sol";
import "../core/Factory.sol";

contract PairTest is Test {
    Pair pair;

    function setUp() public {
        pair = new Pair();
    }

    function testPair() public {
        console.log(address(pair));
    }
}
