/**
 * https://biubiu.tools
 */
// /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\\\\\  /\\\\\\\\      /\\\\\\\\    /\\\          /\\\\\\\\\\
// \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/___/\\\___/ /\\\_____/\\\  /\\\_____/\\\ \/\\\        /\\\_______/
//  \/\\\   \\\   \/\\\    \/\\\   \/\\\ \/\\\   \\\   \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\
//   \/\\\\\\\     \/\\\    \/\\\   \/\\\ \/\\\\\\\     \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\\\\\\\\
//    \/\\\   \\\\  \/\\\    \/\\\   \/\\\ \/\\\   \\\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/_______/\\\
//     \/\\\    \\\  \/\\\    \/\\\   \/\\\ \/\\\    \\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\               \/\\\
//      \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\  \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\      \/\\\    \/_/\\\\\\\\\  \/_/\\\\\\\\\  \/\\\\\\\\\\ /\\\\\\\\\/
//       \/______/   \/______/   \/_______/   \/______/   \/______/   \/_______/       \/_/       \/_______/     \/_______/   \/________/ \/_______/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Utils.sol";

contract TokenLockVault is Initializable {
    uint256 public unlockTime;
    mapping(address => mapping(address => uint256)) private _balances;

    event Withdrawal(uint amount, uint when);

    function init(uint256 endedAt_) public initializer {
        require(
            block.timestamp < endedAt_,
            "Unlock time should be in the future"
        );

        unlockTime = endedAt_;
    }

    function deposit(address token, uint256 amount) public {
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "ERC20 transfer failed"
        );

        _balances[msg.sender][token] += amount;
    }

    function balanceOf(
        address account,
        address token
    ) public view returns (uint256) {
        return _balances[account][token];
    }

    function withdraw(address token) public {
        uint256 balance = _balances[msg.sender][token];
        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(balance > 0, "Insufficient amount");
        require(
            IERC20(token).transfer(msg.sender, balance),
            "ERC20 transfer failed"
        );

        _balances[msg.sender][token] = 0;
    }
}
