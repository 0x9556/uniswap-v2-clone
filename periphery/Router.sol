// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;

import "../core/interfaces/IFactory.sol";

import "./libraries/SwapHelper.sol";
import "./libraries/TransferHelper.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IWETH.sol";

contract Router is IRouter {
    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        if (deadline < block.timestamp) revert Expired();
        _;
    }

    constructor(address _factory, address weth) {
        factory = _factory;
        WETH = weth;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        ensure(deadline)
        returns (uint amountA, uint amountB, uint liquidity)
    {
        (amountA, amountB) = calculateAmount(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        address pair = SwapHelper.pairFor(factory, tokenA, tokenB);

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        ensure(deadline)
        returns (uint amountToken, uint amountETH, uint liquidity)
    {
        (amountToken, amountETH) = calculateAmount(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        address pair = SwapHelper.pairFor(factory, token, WETH);

        IWETH(WETH).deposit{value: amountETH}();

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        TransferHelper.safeTransfer(WETH, pair, amountETH);

        liquidity = IPair(pair).mint(to);

        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        //transfer liquidity to pair contract
        address pair = SwapHelper.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = IPair(pair).burn(to);
        (address token0, ) = SwapHelper.sortTokens(tokenA, tokenB);

        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);

        if (amountAMin > amountA) revert InsufficientAmount("A");
        if (amountBMin > amountB) revert InsufficientAmount("B");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = SwapHelper.pairFor(factory, tokenA, tokenB);
        uint approveAmount = approveMax ? type(uint).max : liquidity;

        IPair(pair).permit(
            msg.sender,
            address(this),
            approveAmount,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external ensure(deadline) returns (uint amountToken, uint amountETH) {
        address pair = SwapHelper.pairFor(factory, token, WETH);
        uint approveAmount = approveMax ? type(uint).max : liquidity;

        IPair(pair).permit(
            msg.sender,
            address(this),
            approveAmount,
            deadline,
            v,
            r,
            s
        );

        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function _swap(
        address[] calldata path,
        uint[] memory amounts,
        address to
    ) private {
        for (uint i = 0; i < path.length - 1; ) {
            (address tokenIn, address tokenOut) = (path[i], path[i + 1]);
            uint amountOut = amounts[i + 1];
            address pair = SwapHelper.pairFor(factory, tokenIn, tokenOut);

            (address token0, ) = SwapHelper.sortTokens(tokenIn, tokenOut);
            (uint amount0Out, uint amount1Out) = token0 == tokenIn
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address _to = i < path.length - 2
                ? to
                : SwapHelper.pairFor(factory, path[i + 1], path[i + 2]);

            IPair(pair).swap(amount0Out, amount1Out, _to, new bytes(0));
            unchecked {
                ++i;
            }
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        uint length = path.length;
        address pair = SwapHelper.pairFor(factory, path[0], path[1]);
        amounts = SwapHelper.getAmountsOut(factory, amountIn, path);

        if (amounts[length - 1] < amountOutMin)
            revert InsufficientAmount("OUTPUT");
        if (path[0] == WETH) {
            TransferHelper.safeTransfer(WETH, pair, amountIn);
        } else {
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amountIn
            );
        }

        _swap(path, amounts, to);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        uint length = path.length;
        if (path[length - 1] != WETH) revert InvalidPath();

        amounts = swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        uint amountETH = amounts[length - 1];
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        if (path[0] != WETH) revert InvalidPath();
        uint amountIn = msg.value;
        IWETH(WETH).deposit();
        amounts = swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint[] memory amounts) {
        address pair = SwapHelper.pairFor(factory, path[0], path[1]);
        amounts = SwapHelper.getAmountsIn(factory, amountOut, path);
        if (amountInMax < amounts[0]) revert InsufficientAmount("INPUT");
        if (path[0] == WETH) {
            TransferHelper.safeTransfer(WETH, pair, amounts[0]);
        } else {
            TransferHelper.safeTransferFrom(
                path[0],
                msg.sender,
                pair,
                amounts[0]
            );
        }

        _swap(path, amounts, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        uint length = path.length;
        if (path[length - 1] != WETH) revert InvalidPath();
        amounts = swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            deadline
        );
        uint amountETH = amounts[length - 1];
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint[] memory amounts) {
        if (path[0] != WETH) revert InvalidPath();
        IWETH(WETH).deposit();
        amounts = swapTokensForExactTokens(
            amountOut,
            msg.value,
            path,
            to,
            deadline
        );
        uint amountETH = amounts[0];

        if (msg.value - amountETH > 0)
            TransferHelper.safeTransferETH(to, amountETH);
    }

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure returns (uint amountB) {
        amountB = SwapHelper.quote(amountA, reserveA, reserveB);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountIn) {
        amountIn = SwapHelper.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure returns (uint amountOut) {
        amountOut = SwapHelper.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) public view returns (uint[] memory amountsIn) {
        amountsIn = SwapHelper.getAmountsIn(factory, amountOut, path);
    }

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) public view returns (uint[] memory amountsOut) {
        amountsOut = SwapHelper.getAmountsOut(factory, amountIn, path);
    }

    //private
    function calculateAmount(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private returns (uint amountA, uint amountB) {
        if (IFactory(factory).pairs(tokenA, tokenB) == address(0)) {
            IFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SwapHelper.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientAmount("B");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert InsufficientAmount("A");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}
