// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library Utils {
    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function bytesToUint(
        bytes memory data
    ) internal pure returns (uint256 value) {
        require(data.length >= 32, "Invalid data length");
        assembly {
            value := mload(add(data, 32))
        }
        return value;
    }

    function bytesToAddress(
        bytes memory data
    ) internal pure returns (address addr) {
        require(data.length == 20, "invalid data");
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }

    function bytesToString(
        bytes memory data
    ) internal pure returns (string memory) {
        return string(data);
    }

    function pseudoRandomNo(
        uint number,
        uint256 seed
    ) internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.coinbase,
                        tx.gasprice,
                        gasleft(),
                        seed
                    )
                )
            ) % number;
    }
}
