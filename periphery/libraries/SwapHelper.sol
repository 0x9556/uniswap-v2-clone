// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "../../core/interfaces/IPair.sol";

library SwapHelper {
    error ZeroAddress();
    error InvalidPath();
    error IndenticalAddress();
    error InsufficientAmount();
    error InsufficientLiquidity();

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IndenticalAddress();
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();

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
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"895250781f3d96785fe028fb3ca8feaa193a0a7394f1f5fb30566cb441487b49"
                        )
                    )
                )
            )
        );
    }

    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        address pair = pairFor(factory, token0, token1);
        (uint reserve0, uint reserve1, ) = IPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? ((reserve0), (reserve1))
            : ((reserve1), (reserve0));
    }

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        if (amountA == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        uint length = path.length;
        if (length < 2) revert InvalidPath();
        amounts = new uint[](length);
        amounts[0] = amountIn;

        for (uint i = 0; i < length - 1; ) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );

            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
            unchecked {
                ++i;
            }
        }
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        if (amountOut == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        uint numerator = amountOut * reserveIn * 1000;
        uint demominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / demominator) + 1; //integer division,rounds down,make sure amountOut >0
    }

    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amountsIn) {
        uint length = path.length;
        if (length < 2) revert InvalidPath();
        amountsIn = new uint[](length);
        amountsIn[length - 1] = amountOut;

        for (uint i = length - 1; i > 0; ) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );

            amountsIn[i - 1] = getAmountIn(amountsIn[i], reserveIn, reserveOut);
            unchecked {
                --i;
            }
        }
    }
}
