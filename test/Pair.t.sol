// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "../core/Pair.sol";
import "../core/Factory.sol";

contract ERC20Test is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint value) external {
        _mint(to, value);
    }
}

contract PairTest is Test {
    Factory factory;
    address pair;
    address token0;
    address token1;

    function setUp() public {
        factory = new Factory(msg.sender);
        ERC20Test tokenA = new ERC20Test("TestToken", "T1");
        ERC20Test tokenB = new ERC20Test("TestToken", "T2");

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

        assertEq(ERC20Test(token0).balanceOf(pair), token0Amount);
        assertEq(ERC20Test(token1).balanceOf(pair), token1Amount);
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
        assertEq(ERC20Test(token0).balanceOf(pair), 1000);
        assertEq(ERC20Test(token1).balanceOf(pair), 1000);

        uint token0TotalSupply = ERC20Test(token0).totalSupply();
        uint token1TotalSupply = ERC20Test(token1).totalSupply();
        assertEq(
            ERC20Test(token0).balanceOf(address(this)),
            token0TotalSupply - 1000
        );
        assertEq(
            ERC20Test(token1).balanceOf(address(this)),
            token1TotalSupply - 1000
        );
    }

    //internal
    function addLiquidity(uint token0Amount, uint token1Amount) private {
        ERC20Test(token0).transfer(pair, token0Amount);
        ERC20Test(token1).transfer(pair, token1Amount);
        Pair(pair).mint(address(this));
    }
}
