// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IToken {
    function init(
        address owner,
        string memory name,
        string memory symbol,
        bytes[] memory data
    ) external;

    function eip() external returns (string memory);
}

struct TokenCreatedLog {
    string eip;
    address tokenAddr;
    uint256 createdAt;
}

interface INFTFactory is IERC165 {
    event TokenCreated(address indexed newTokenAddr, string indexed eip);

    function createToken(
        string memory eip,
        string memory name,
        string memory symbol,
        bytes[] memory data
    ) external payable returns (address newTokenAddr);

    function queryLogsCount(address user) external view returns (uint256);
}
