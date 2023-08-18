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
        uint expectLiquidity = 2 ether - Pair(pair).MINIMUM_LIQUIDITY();
        ERC20Test(token0).transfer(pair, token0Amount);
        ERC20Test(token1).transfer(pair, token1Amount);

        uint liquidity = Pair(pair).mint(address(this));
        assertEq(liquidity, expectLiquidity);
    }
}
