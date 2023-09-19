// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AbstractRedrop.sol";

contract Redrop102 is AbstractRedrop {
    function eip() public pure override returns (string memory) {
        return "Redrop102";
    }

    function request() public override {}

    function claim(address referrer) public override {
        RedropCreatedLog memory info = _beforeClaim();

        // Calculate amount
        uint256 amount = info.totalAmount / info.maxRecipients;

        // Transfer
        _transferAmount(info.tokenAddress, amount, referrer);
    }
}
