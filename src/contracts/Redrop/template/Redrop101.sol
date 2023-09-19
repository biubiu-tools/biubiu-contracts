// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../Utils.sol";
import "../IRedropFactory.sol";
import "./AbstractRedrop.sol";

contract Redrop101 is AbstractRedrop {
    function eip() public pure override returns (string memory) {
        return "Redrop101";
    }

    function request() public override {
        IRedropFactory factory = IRedropFactory(redropFactory);
        RedropCreatedLog memory info = factory.getRedropInfo(address(this));
        uint256 startedAt = info.startedAt;
        uint256 endedAt = info.endedAt;
        uint256 maxRecipients = info.maxRecipients;

        require(
            blockHashesToBeUsed[msg.sender] == 0 &&
                startedAt < block.timestamp &&
                block.timestamp < endedAt &&
                totalClaimedUser < maxRecipients,
            "Request: Not within the activity period."
        );

        blockHashesToBeUsed[msg.sender] =
            block.number +
            2 +
            Utils.pseudoRandomNo(3, totalClaimedUser);

        emit RequestCreated(
            address(this),
            msg.sender,
            blockHashesToBeUsed[msg.sender]
        );
    }

    function _calculateShares(
        uint256 totalShares,
        uint256 luckyNumber,
        uint256 maxRecipients
    ) private view returns (uint256) {
        uint256 averageShares = totalShares / maxRecipients;
        uint256 minShares = averageShares / 2;
        uint256 maxShares = totalShares / 50;

        uint8 prime = 3;

        if (maxRecipients >= 10) {
            prime = 7;
        }

        if (maxRecipients >= 100) {
            prime = 17;
        }

        if (maxRecipients >= 1000) {
            prime = 23;
        }

        if (luckyNumber % prime == 0) {
            maxShares = totalShares;
        }

        uint256 userShares = Utils.pseudoRandomNo(maxShares, luckyNumber);

        if (userShares < minShares) {
            userShares = minShares;
        }

        // MAX 36%
        if (userShares > (totalShares * 36) / 100) {
            userShares = (totalShares * 36) / 100;
        }
        //  The last user gets all the remaining
        if ((totalClaimedUser + 1) == maxRecipients) {
            userShares = totalShares;
        }

        return userShares;
    }

    function _onetimeRandomNo(
        uint number,
        address user
    ) private view returns (uint) {
        bytes32 blockHash = blockhash(blockHashesToBeUsed[user]);
        return uint(blockHash) % number;
    }

    function _calculateAmount(
        address user,
        uint256 maxRecipients,
        uint256 totalAmount,
        address tokenAddress
    ) internal view returns (uint256) {
        uint256 luckyNumber = _onetimeRandomNo(1000, user);
        uint256 totalShares = 10_000_000;
        uint256 userShares = _calculateShares(
            totalShares,
            luckyNumber,
            maxRecipients
        );

        // Calculate amount
        uint256 amount = totalAmount / maxRecipients;

        if (tokenAddress == address(0)) {
            amount = (userShares * address(this).balance) / (totalShares);
        } else {
            IERC20 erc20Token = IERC20(tokenAddress);
            amount =
                (userShares * erc20Token.balanceOf(address(this))) /
                (totalShares);
        }
        return amount;
    }

    function claim(address referrer) public override {
        RedropCreatedLog memory info = _beforeClaim();

        require(
            blockHashesToBeUsed[msg.sender] != 0,
            "Claim: You need to request first..."
        );

        require(
            block.number >= blockHashesToBeUsed[msg.sender],
            "Claim: You need to wait..."
        );

        require(
            block.number - blockHashesToBeUsed[msg.sender] <= 250,
            "Claim: You have timed out and cannot claim"
        );

        // Calculate amount
        uint256 amount = _calculateAmount(
            msg.sender,
            info.maxRecipients,
            info.totalAmount,
            info.tokenAddress
        );

        // Transfer
        _transferAmount(info.tokenAddress, amount, referrer);
    }
}
