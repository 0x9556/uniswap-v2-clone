// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "./ERC20Mintable.sol";

import "../periphery/libraries/SwapHelper.sol";
import "../periphery/Router.sol";
import "../core/Factory.sol";
import "../core/Pair.sol";

contract RouterHelper is Test {
    address constant deployer = address(1);
    address constant user = address(2);
    uint constant MINIMUM_LIQUIDITY = 1000;

    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    WETH weth;
    Pair pair;
    Pair wethPair;
    Factory factory;
    Router router;

    function setUp() public {
        factory = new Factory(deployer);

        tokenA = new ERC20Mintable("TestToken", "TA");
        tokenB = new ERC20Mintable("TestToken", "TB");
        weth = new WETH();

        router = new Router(address(factory), address(weth));
        pair = Pair(factory.createPair(address(tokenA), address(tokenB)));
        wethPair = Pair(factory.createPair(address(tokenB), address(weth)));

        tokenA.mint(address(this), 10000 ether);
        tokenB.mint(address(this), 10000 ether);
    }
}
