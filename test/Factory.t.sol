// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../core/Factory.sol";
import "../core/Pair.sol";

contract FactoryTest is Test {
    address constant tokenA =
        address(0x1000000000000000000000000000000000000000);
    address constant tokenB =
        address(0x2000000000000000000000000000000000000000);

    Factory factory;

    function setUp() public {
        factory = new Factory(address(this));
    }

    function test_feeTo_feeToSetter_allPairsLength() public {
        assertEq(factory.feeTo(), address(0));
        assertEq(factory.feeToSetter(), address(this));
        assertEq(factory.allPairsLength(), 0);
    }

    function testCreatePair() public {
        address create2Address = pairFor(address(factory), tokenA, tokenB);
        address pair = factory.createPair(tokenA, tokenB);

        vm.expectRevert();
        factory.createPair(tokenA, tokenB);
        vm.expectRevert();
        factory.createPair(tokenB, tokenA);

        assertEq(create2Address, pair);
        assertEq(factory.pairs(tokenA, tokenB), pair);
        assertEq(factory.pairs(tokenB, tokenA), pair);
        assertEq(factory.allPairs(0), pair);
        assertEq(factory.allPairsLength(), 1);

        assertEq(Pair(pair).token0(), tokenA);
        assertEq(Pair(pair).token1(), tokenB);
        assertEq(Pair(pair).factory(), address(factory));
    }

    function testSetFeeTo() public {
        vm.prank(msg.sender);
        vm.expectRevert();
        factory.setFeeTo(address(0));

        factory.setFeeTo(msg.sender);
        assertEq(factory.feeTo(), msg.sender);
    }

    function testSetFeeToSetter() public {
        vm.prank(msg.sender);
        vm.expectRevert();
        factory.setFeeToSetter(address(msg.sender));

        factory.setFeeToSetter(msg.sender);
        assertEq(factory.feeToSetter(), msg.sender);
    }

    //internal

    function pairFor(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(Pair).creationCode)
                        )
                    )
                )
            )
        );
    }
}
