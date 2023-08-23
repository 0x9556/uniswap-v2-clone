// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "./RouterHelper.sol";

contract RouterTest is RouterHelper {
    function test_factory_WETH() public {
        assertEq(router.factory(), address(factory));
        assertEq(router.WETH(), address(weth));
    }

    function test_addLiquidity() public {
        ERC20(tokenA).approve(address(router), type(uint).max);
        ERC20(tokenB).approve(address(router), type(uint).max);

        uint tokenAAmount = 1 ether;
        uint tokenBAmount = 4 ether;
        uint expectLiquidity = 2 ether - MINIMUM_LIQUIDITY;

        (, , uint liquidity) = IRouter(router).addLiquidity(
            address(tokenA),
            address(tokenB),
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            address(this),
            type(uint).max
        );

        assertEq(liquidity, expectLiquidity);
        assertEq(address(router).balance, 0);
    }

    function test_addLiquidityETH() public {
        ERC20(tokenB).approve(address(router), type(uint).max);

        uint tokenBAmount = 1 ether;
        uint ETHAmount = 4 ether;
        uint expectLiquidity = 2 ether - MINIMUM_LIQUIDITY;

        (, , uint liquidity) = IRouter(router).addLiquidityETH{
            value: ETHAmount
        }(address(tokenB), tokenBAmount, 0, 0, address(this), type(uint).max);

        assertEq(liquidity, expectLiquidity);
        assertEq(address(router).balance, 0);
    }

    function test_removeLiquidity() public {
        uint liquidity = addLiquidity(1 ether, 4 ether);
        pair.approve(address(router), type(uint).max);

        IRouter(router).removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0,
            0,
            user,
            type(uint).max
        );

        uint expectAmountA = 1 ether - 500;
        uint expectAmountB = 4 ether - 2000;

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(tokenA.balanceOf(user), expectAmountA);
        assertEq(tokenB.balanceOf(user), expectAmountB);
    }

    //internal

    function addLiquidity(
        uint tokenAAmount,
        uint tokenBAmount
    ) internal returns (uint liquidity) {
        tokenA.transfer(address(pair), tokenAAmount);
        tokenB.transfer(address(pair), tokenBAmount);
        liquidity = pair.mint(address(this));
    }
}
