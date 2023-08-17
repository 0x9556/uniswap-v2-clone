// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "../core/Pair.sol";
import "../core/Factory.sol";

// contract PairTest is Test {
//     Factory factory;
//     Pair pair;
//     address token0;
//     address token1;

//     function setUp() public {
//         factory = new Factory(msg.sender);
//         ERC20 tokenA = new ERC20("TestToken", "T1");
//         ERC20 tokenB = new ERC20("TestToken", "T2");

//         tokenA.mint(address(this), 10000 * 10 ** 18);
//         tokenB.mint(address(this), 10000 * 10 ** 18);

//         pair = factory.createPair(address(tokenA), address(tokenB));

//         address token0Address = pair.token0;

//         (token0, token1) = address(tokenA) == token0Address
//             ? (address(tokenA), address(tokenB))
//             : (address(tokenB), address(tokenA));
//     }
// }
