// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AbstractRedrop.sol";

contract Redrop103 is AbstractRedrop {
    function eip() public pure override returns (string memory) {
        return "Redrop103";
    }

    function request() public override {}

    function claim(address /*referrer*/) public override {
        RedropCreatedLog memory info = _beforeClaim();

        // Calculate share
        IERC20 dt = IERC20(info.dividendToken);
        uint256 share = dt.balanceOf(msg.sender);
        uint256 totalSupply = dt.totalSupply();

        // Calculate amount
        uint256 amount = (info.totalAmount * share) / totalSupply;

        // Transfer
        _transferAmount(info.tokenAddress, amount, address(0));

        // Lock
        ITokenLockVault(tokenLockVault).deposit(info.dividendToken, share);
    }
}
