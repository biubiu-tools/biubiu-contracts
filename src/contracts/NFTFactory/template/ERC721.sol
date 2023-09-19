// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract ERC721Token is ERC721, Initializable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _name;
    string private _symbol;

    // features
    bool public isTransferAllowed;

    constructor() ERC721("MyToken", "MTK") {}

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

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        require(
            isTransferAllowed || msg.sender == owner(),
            "isTransferAllowed: false"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // utils
    function parseBoolean(bytes memory data) public pure returns (bool) {
        require(data.length >= 1, "Invalid data length");
        uint8 value = uint8(data[0]);
        require(value <= 1, "Invalid boolean value");
        return value == 1;
    }

    function eip() public pure returns (string memory) {
        return "ERC721";
    }
}
