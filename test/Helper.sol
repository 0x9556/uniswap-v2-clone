// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "solmate/tokens/WETH.sol";
import "./ERC20Mintable.sol";
import "../periphery/libraries/SwapHelper.sol";
import "../core/interfaces/IFactory.sol";

library Helper {
    function createPair(
        address factory,
        uint amountA,
        uint amountB
    ) internal returns (address pair, address tokenA, address tokenB) {
        ERC20Mintable _tokenA = new ERC20Mintable("TestToken", "TA");
        ERC20Mintable _tokenB = new ERC20Mintable("TestToken", "TB");

        _tokenA.mint(msg.sender, amountA);
        _tokenB.mint(msg.sender, amountB);

        (tokenA, tokenB) = (address(_tokenA), address(_tokenB));

        pair = IFactory(factory).createPair(tokenA, tokenB);
    }

    function createWETHPair(
        address factory,
        uint amountToken
    ) internal returns (address pair, address token, address weth) {
        ERC20Mintable _token = new ERC20Mintable("TestToken", "T");
        WETH _weth = new WETH();

        _token.mint(msg.sender, amountToken);

        (token, weth) = (address(_token), address(_weth));

        pair = IFactory(factory).createPair(token, weth);
    }
}
