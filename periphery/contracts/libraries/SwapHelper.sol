// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "../interfaces/IPair.sol";

library SwapHelper {
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)), //salt
                            hex"836bbf1d8ddcdebc607667f76d3a10265fc29619b2ac7be9c3cc0ee1260af79a"
                        )
                    )
                )
            )
        );
    }

    function getReserves(
        address factoryAddress,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        address pairAddress = pairFor(factoryAddress, token0, token1);
        IPair pair = IPair(pairAddress);
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (reserveA, reserveB) = token0 == tokenA
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    function quote(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "InsufficientAmount");
        require(reserveIn != 0 && reserveOut != 0, "InsufficientLiquidity");
        amountOut = (amountIn * reserveOut) / reserveIn;
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "InsufficientAmount");
        require(reserveIn > 0 && reserveOut > 0, "InsufficientLiquidity");
        uint amountInWithFee = amountIn * 997;
        uint numerator = reserveOut * amountInWithFee;
        uint denominator = (reserveIn * 1000 + amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountsOut(
        address factoryAddress,
        uint amountIn,
        address[] calldata path
    ) internal view returns (uint[] memory) {
        uint[] memory amounts = new uint[](path.length);
        amounts[0] = amountIn;

        for (uint i = 0; i < path.length - 1; ) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factoryAddress,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            unchecked {
                i++;
            }
        }

        return amounts;
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "InsufficientAmount");
        require(reserveIn > 0 && reserveOut > 0, "InsufficientLiquidity");

        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsIn(
        address factoryAddress,
        uint amountOut,
        address[] calldata path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[path.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; ) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factoryAddress,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
            unchecked {
                i--;
            }
        }
    }
}
