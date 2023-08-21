// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import "../periphery/Router.sol";
import "../core/Factory.sol";

import "./ERC20Mintable.sol";
import "./Helper.sol";

contract RouterTest is Test {
    address tokenA;
    address tokenB;
    address weth;
    address wethPartner;
    address factory;
    address router;
    address pair;
    address wethPair;

    function setUp() public {
        factory = address(new Factory(msg.sender));
        (pair, tokenA, tokenB) = Helper.createPair(
            factory,
            10000 ether,
            10000 ether
        );
        (wethPair, wethPartner, weth) = Helper.createWETHPair(
            factory,
            10000 ether
        );
        router = address(new Router(factory, weth));
    }

    function test_factory_WETH() public {
        assertEq(IRouter(router).factory(), factory);
        assertEq(IRouter(router).WETH(), weth);
    }

    function test_addLiquidity() public {
        ERC20(tokenA).approve(address(this), type(uint).max);
        ERC20(tokenB).approve(address(this), type(uint).max);

        (, , uint liquidity) = IRouter(router).addLiquidity(
            tokenA,
            tokenB,
            1 ether,
            4 ether,
            0,
            0,
            msg.sender,
            type(uint).max
        );
        uint expectLiquidity = 2 ether - IPair(pair).MINIMUM_LIQUIDITY();

        assertEq(liquidity, expectLiquidity);
    }
}
