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

        (uint amountA, uint amountB, uint liquidity) = IRouter(router)
            .addLiquidity(
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
        assertEq(amountA, 1 ether);
        assertEq(amountB, 4 ether);
    }
}
