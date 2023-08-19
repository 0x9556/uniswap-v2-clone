// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./interfaces/IFactory.sol";
import "./libraries/SwapHelper.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IWETH.sol";

contract Router {
    address public immutable factory;
    address public immutable WETH;

    modifier checkIfPairCreated(address tokenA, address tokenB) {
        if (IFactory(factory).pairs(tokenA, tokenB) == address(0)) {
            IFactory(factory).createPair(tokenA, tokenB);
        }
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    // add liquidity
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    )
        external
        checkIfPairCreated(tokenA, tokenB)
        returns (uint amountA, uint amountB, uint liquidity)
    {
        (amountA, amountB) = _calculateLiquidity(
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
        address to
    )
        external
        payable
        checkIfPairCreated(token, WETH)
        returns (uint amountToken, uint amountETH, uint liquidity)
    {
        (amountToken, amountETH) = _calculateLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SwapHelper.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, to, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IPair(pair).mint(to);

        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    //removeliquidity
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) public returns (uint amountA, uint amountB) {
        //send LP to pair contract
        address pair = SwapHelper.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity);
        //burn
        (uint amount0, uint amount1) = IPair(pair).burn(to);
        (address token0, ) = SwapHelper.sortTokens(tokenA, tokenB);
        (amountA, amountB) = token0 == tokenA
            ? (amount0, amount1)
            : (amount1, amount0);
        require(
            amountA >= amountAMin && amountB >= amountBMin,
            "Insufficient Amount"
        );
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to
    ) public returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this)
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = SwapHelper.pairFor(factory, tokenA, tokenB);
        uint amount = approveMax ? type(uint).max : liquidity;
        IPair(pair).permit(msg.sender, address(this), amount, v, r, s);
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = SwapHelper.pairFor(factory, token, WETH);
        uint amount = approveMax ? type(uint).max : liquidity;
        IPair(pair).permit(msg.sender, address(this), amount, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to
        );
    }

    //swap
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        uint[] memory amounts = SwapHelper.getAmountsOut(
            factory,
            amountIn,
            path
        );

        require(
            amounts[path.length - 1] > amountOutMin,
            "InsufficientOutputAmount"
        );

        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapHelper.pairFor(factory, path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        require(path[path.length - 1] == WETH, "INVALID_PATH");
        uint[] memory amounts = SwapHelper.getAmountsOut(
            factory,
            amountIn,
            path
        );
        uint amountOut = amounts[path.length - 1];
        require(amountOut >= amountOutMin, "InsufficientOutputAmount");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapHelper.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapExactETHForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to
    ) external {
        require(path[0] == WETH, "INVALID_PATH");
        uint[] memory amounts = SwapHelper.getAmountsOut(
            factory,
            amountIn,
            path
        );
        require(
            amounts[path.length - 1] > amountOutMin,
            "InsufficientOutputAmount"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                SwapHelper.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external {
        uint[] memory amounts = SwapHelper.getAmountsIn(
            factory,
            amountOut,
            path
        );
        uint amountIn = amounts[0];
        require(amountIn <= amountInMax, "ExcessiveInputAmount");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapHelper.pairFor(address(factory), path[0], path[1]),
            amountIn
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external {
        require(path[path.length - 1] == WETH, "INVALID_PATH");
        uint[] memory amounts = SwapHelper.getAmountsIn(
            factory,
            amountOut,
            path
        );
        uint amountIn = amounts[0];
        require(amountIn <= amountInMax, "ExcessiveInputAmount");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            SwapHelper.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapETHForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to
    ) external {
        require(path[0] == WETH, "INVALID_PATH");
        uint[] memory amounts = SwapHelper.getAmountsIn(
            factory,
            amountOut,
            path
        );
        uint amountIn = amounts[0];
        require(amountIn <= amountInMax, "ExcessiveInputAmount");
        IWETH(WETH).deposit{value: amountIn}();
        assert(
            IWETH(WETH).transfer(
                SwapHelper.pairFor(factory, path[0], path[1]),
                amountIn
            )
        );
        _swap(amounts, path, to);
    }

    function _swap(
        uint[] memory amounts,
        address[] calldata path,
        address _to
    ) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = SwapHelper.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? SwapHelper.pairFor(factory, output, path[i + 2])
                : _to;
            IPair(SwapHelper.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function _calculateLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) private view returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB) = SwapHelper.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SwapHelper.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal > amountBMin, "INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SwapHelper.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}
