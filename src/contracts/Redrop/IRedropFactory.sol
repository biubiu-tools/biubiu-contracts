// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

struct RedropCreatedLog {
    // key info
    string eip;
    address redropAddr;
    uint256 createdAt;
    // info
    address sender;
    address guardAddr;
    address tokenAddress; // 0x0 => ETH ,otherwise ERC20
    uint256 maxRecipients;
    uint256 totalAmount;
    string greetings;
    uint256 startedAt;
    uint256 endedAt;
    address dividendToken;
    // link
    string url;
    // memo
    string memo;
}

interface IRedropFactory is IERC165 {
    event RedropCreated(address indexed newRedropAddr, string indexed eip);

    function createRedrop(
        string memory eip,
        string memory guardType,
        bytes[] memory guardArgs,
        bytes[] memory redropArgs
    ) external payable returns (address newRedropAddr);

    function queryLogsCount(address user) external view returns (uint256);

    function getRedropInfo(
        address addr
    ) external view returns (RedropCreatedLog memory);

    function tokenLockVaultTemplate() external view returns (address);

    function batchRefund(address[] calldata list) external;
}
