// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../core/Pair.sol";
import "../core/Factory.sol";
import "./ERC20Mintable.sol";

contract PairTest is Test {
    Factory factory;
    address pair;
    address token0;
    address token1;

    function setUp() public {
        factory = new Factory(msg.sender);
        ERC20Mintable tokenA = new ERC20Mintable("TestToken", "T1");
        ERC20Mintable tokenB = new ERC20Mintable("TestToken", "T2");

        tokenA.mint(address(this), 10000 * 10 ** 18);
        tokenB.mint(address(this), 10000 * 10 ** 18);

        pair = factory.createPair(address(tokenA), address(tokenB));

        address token0Address = Pair(pair).token0();

        (token0, token1) = address(tokenA) == token0Address
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));
    }

    function testMint() public {
        uint token0Amount = 1 ether;
        uint token1Amount = 4 ether;
        uint expectLiquidity = 2 ether;
        addLiquidity(token0Amount, token1Amount);

        assertEq(ERC20Mintable(token0).balanceOf(pair), token0Amount);
        assertEq(ERC20Mintable(token1).balanceOf(pair), token1Amount);
        assertEq(Pair(pair).totalSupply(), 2 ether);
        assertEq(
            Pair(pair).balanceOf(address(this)),
            expectLiquidity - Pair(pair).MINIMUM_LIQUIDITY()
        );

        (uint112 reserve0, uint112 reserve1, ) = Pair(pair).getReserves();
        assertEq(reserve0, token0Amount);
        assertEq(reserve1, token1Amount);
    }

    function testBurn() public {
        uint token0Amount = 2 ether;
        uint token1Amount = 2 ether;
        uint MINIMUM_LIQUIDITY = Pair(pair).MINIMUM_LIQUIDITY();
        uint expectLiquidity = 2 ether - MINIMUM_LIQUIDITY;
        addLiquidity(token0Amount, token1Amount);

        Pair(pair).transfer(pair, expectLiquidity);
        Pair(pair).burn(address(this));

        assertEq(Pair(pair).balanceOf(address(this)), 0);
        assertEq(Pair(pair).totalSupply(), MINIMUM_LIQUIDITY);
        assertEq(ERC20Mintable(token0).balanceOf(pair), 1000);
        assertEq(ERC20Mintable(token1).balanceOf(pair), 1000);

        uint token0TotalSupply = ERC20Mintable(token0).totalSupply();
        uint token1TotalSupply = ERC20Mintable(token1).totalSupply();
        assertEq(
            ERC20Mintable(token0).balanceOf(address(this)),
            token0TotalSupply - 1000
        );
        assertEq(
            ERC20Mintable(token1).balanceOf(address(this)),
            token1TotalSupply - 1000
        );
    }

    //internal
    function addLiquidity(uint token0Amount, uint token1Amount) private {
        ERC20Mintable(token0).transfer(pair, token0Amount);
        ERC20Mintable(token1).transfer(pair, token1Amount);
        Pair(pair).mint(address(this));
    }
}
