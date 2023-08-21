// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "./ERC20Mintable.sol";
import "../periphery/libraries/SwapHelper.sol";
import "../core/Factory.sol";

library Helper {
    function createPair(
        uint amountA,
        uint amountB
    )
        internal
        returns (address token0, address token1, address factory, address pair)
    {
        ERC20Mintable tokenA = new ERC20Mintable("TestToken", "TA");
        ERC20Mintable tokenB = new ERC20Mintable("TestToken", "TB");
        tokenA.mint(msg.sender, amountA);
        tokenB.mint(msg.sender, amountB);

        (token0, token1) = SwapHelper.sortTokens(
            address(tokenA),
            address(tokenB)
        );

        Factory _factory = new Factory(msg.sender);
        pair = _factory.createPair(address(tokenA), address(tokenB));
        factory = address(_factory);
    }
}
