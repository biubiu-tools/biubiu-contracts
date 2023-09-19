// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IGuard.sol";
import "../Utils.sol";

contract ETHMin is Initializable, IGuard {
    uint256 public min;

    string public constant guardType = "ETHMin";

    function init(bytes[] calldata data_) public initializer {
        require(data_.length == 1, "Invalid initialization data");
        min = Utils.bytesToUint(data_[0]);
    }

    function canAccess(address visitor) public view returns (bool) {
        return address(visitor).balance >= min;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IGuard).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
