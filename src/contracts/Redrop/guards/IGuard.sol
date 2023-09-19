// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IGuard is IERC165 {
    function init(bytes[] calldata data) external;

    function guardType() external returns (string memory);

    function canAccess(address visitor) external returns (bool);
}
