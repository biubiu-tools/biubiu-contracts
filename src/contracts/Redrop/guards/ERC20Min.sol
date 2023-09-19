// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IGuard.sol";
import "../Utils.sol";

contract ERC20Min is Initializable, IGuard {
    address public tokenAddr;
    uint256 public min;

    string public constant guardType = "ERC20Min";

    function init(bytes[] calldata data_) public initializer {
        require(data_.length == 2, "Invalid initialization data");
        tokenAddr = Utils.bytesToAddress(data_[0]);
        min = Utils.bytesToUint(data_[1]);
        require(IERC20(tokenAddr).totalSupply() > 0, "Invalid token address");
    }

    function canAccess(address visitor) public view returns (bool) {
        IERC20 token = IERC20(tokenAddr);
        return token.balanceOf(visitor) >= min;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IGuard).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
