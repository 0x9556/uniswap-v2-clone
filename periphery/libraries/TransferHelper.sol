// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

library TransferHelper {
    function safeApprove(address token, address to, uint amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "Approve Failed"
        );
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
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferFrom Failed"
        );
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transfer failed"
        );
    }

    function safeTransferETH(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "ETH transfer failed");
    }
}
