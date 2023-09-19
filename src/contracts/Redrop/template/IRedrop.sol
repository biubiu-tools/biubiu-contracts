// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

struct ClaimLog {
    address visitor;
    address referrer;
    uint256 visitorAmount;
    uint256 referrerAmount;
    uint256 claimedAt;
}

interface IRedrop is IERC165 {
    event RequestCreated(
        address indexed tokenAddr,
        address indexed visitor,
        uint256 indexed blocknumber
    );

    event Claimed(
        address indexed tokenAddr,
        address indexed visitor,
        uint256 indexed amount
    );

    function init() external;

    function eip() external returns (string memory);

    function request() external;

    function claim(address referrer) external;

    function refund() external;
}
