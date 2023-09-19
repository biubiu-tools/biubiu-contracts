// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IGuard.sol";
import "../Utils.sol";

contract ERC721Holder is Initializable, IGuard {
    address public tokenAddr;

    string public constant guardType = "ERC721Holder";

    function init(bytes[] calldata data_) public initializer {
        require(data_.length == 1, "Invalid initialization data");
        tokenAddr = Utils.bytesToAddress(data_[0]);
        require(
            IERC165(tokenAddr).supportsInterface(type(IERC721).interfaceId),
            "Invalid token address"
        );
    }

    function canAccess(address visitor) public view returns (bool) {
        IERC721 token = IERC721(tokenAddr);
        return token.balanceOf(visitor) >= 1;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IGuard).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
