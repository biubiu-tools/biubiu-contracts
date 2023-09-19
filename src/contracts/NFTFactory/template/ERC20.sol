// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ERC20Token is ERC20, Initializable, Ownable {
    string private _name;
    string private _symbol;

    // features
    bool public isTransferAllowed;

    constructor() ERC20("MyToken", "MTK") {}

    // data_:
    // 0=> premint      // 0x0000000000000000000000000000000000000000000000000000000000000001
    // 1=> isTransferAllowed  //0x01

    function init(
        address owner_,
        string memory name_,
        string memory symbol_,
        bytes[] memory data_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;

        // premint or not
        uint256 premint = bytesToUint(data_[0]);
        _transferOwnership(msg.sender);
        if (premint >= 1) {
            _mint(owner_, premint * 10 ** decimals());
        }
        _transferOwnership(owner_);
        isTransferAllowed = parseBoolean(data_[1]);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            isTransferAllowed || msg.sender == owner(),
            "isTransferAllowed: false"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // utils
    function bytesToUint(bytes memory data) public pure returns (uint256) {
        require(data.length >= 32, "Invalid data length");
        uint256 value;
        assembly {
            value := mload(add(data, 32))
        }
        return value;
    }

    function parseBoolean(bytes memory data) public pure returns (bool) {
        require(data.length >= 1, "Invalid data length");
        uint8 value = uint8(data[0]);
        require(value <= 1, "Invalid boolean value");
        return value == 1;
    }

    function eip() public pure returns (string memory) {
        return "ERC20";
    }
}
