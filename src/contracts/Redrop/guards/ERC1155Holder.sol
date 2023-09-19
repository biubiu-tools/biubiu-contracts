// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IGuard.sol";
import "../Utils.sol";

contract ERC1155Holder is Initializable, IGuard {
    address public tokenAddr;
    uint256 public tokenId;

    string public constant guardType = "ERC1155Holder";

    function init(bytes[] calldata data_) public initializer {
        require(data_.length == 2, "Invalid initialization data");
        tokenAddr = Utils.bytesToAddress(data_[0]);
        tokenId = Utils.bytesToUint(data_[1]);

        require(
            IERC165(tokenAddr).supportsInterface(type(IERC1155).interfaceId),
            "Invalid token address"
        );
    }

    function canAccess(address visitor) public view returns (bool) {
        IERC1155 token = IERC1155(tokenAddr);
        return token.balanceOf(visitor, tokenId) >= 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IGuard).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
