// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Token is ERC1155, Initializable, Ownable {
    string private _name;
    string private _symbol;

    // features
    bool public isTransferAllowed;

    constructor() ERC1155("") {}

    // data_:
    // 0=> isTransferAllowed  //0x01

    function init(
        address owner_,
        string memory name_,
        string memory symbol_,
        bytes[] memory data_
    ) public initializer {
        _name = name_;
        _symbol = symbol_;
        _transferOwnership(owner_);

        isTransferAllowed = parseBoolean(data_[0]);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        require(
            isTransferAllowed || msg.sender == owner(),
            "isTransferAllowed: false"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // utils
    function parseBoolean(bytes memory data) public pure returns (bool) {
        require(data.length >= 1, "Invalid data length");
        uint8 value = uint8(data[0]);
        require(value <= 1, "Invalid boolean value");
        return value == 1;
    }

    function eip() public pure returns (string memory) {
        return "ERC1155";
    }
}
