// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IGuard.sol";

contract All is Initializable, IGuard {
    string public constant guardType = "All";

    function init(bytes[] calldata data_) public initializer {}

    function canAccess(address visitor) public pure returns (bool) {
        return visitor != address(0);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IGuard).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
