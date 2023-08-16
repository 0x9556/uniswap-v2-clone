// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./interfaces/ILPERC20.sol";

contract LPERC20 is ILPERC20 {
    string public constant name = "LP-Token";
    string public constant symbol = "LP";
    uint8 public constant decimals = 18;
    uint public totalSupply;

    bytes32 public immutable DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public nonces;

    constructor() {
        uint chainId = block.chainid;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifying(Contract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool) {
        uint allowed = allowance[from][msg.sender];
        if (allowed != type(uint).max)
            allowance[from][msg.sender] = allowed - amount;
        _transfer(from, to, amount);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint amount,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        unchecked {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            amount,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
            address recoverdAddress = ecrecover(messageHash, v, r, s);
            require(
                recoverdAddress != address(0) && recoverdAddress == owner,
                "INVALID_SIGNER"
            );
            allowance[owner][spender] = amount;
        }
        emit Approval(owner, spender, amount);
    }

    function _mint(address to, uint amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint amount) internal {
        totalSupply -= amount;
        balanceOf[from] -= amount;
        emit Transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }
}

// contract MyERC20 is ERC20 {
//     constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

//     function mint(address to, uint amount) external returns (bool) {
//         _mint(to, amount);
//         return true;
//     }
// }
