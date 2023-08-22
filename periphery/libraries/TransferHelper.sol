// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

library TransferHelper {
    error ApproveFaild();
    error TransferFailed(string);

    function safeApprove(address token, address to, uint amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        if (!success || !(data.length == 0 || abi.decode(data, (bool))))
            revert ApproveFaild();
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint amount
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                amount
            )
        );
        if (!success || !(data.length == 0 || abi.decode(data, (bool))))
            revert TransferFailed("TRANSFER_FROM");
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        if (!success || !(data.length == 0 || abi.decode(data, (bool))))
            revert TransferFailed("TRANSFER");
    }

    function safeTransferETH(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) revert TransferFailed("ETH");
    }
}
