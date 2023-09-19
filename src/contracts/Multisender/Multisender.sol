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
import "./IMultisender.sol";

contract Multisender is IMultisender {
    address treasury;

    constructor(address treasury_) {
        treasury = treasury_;
    }

    function sendETH(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 total
    ) public payable override {
        checkLen(recipients.length, amounts.length);
        require(msg.value >= total, "insuffix balance");
        uint256 fee = msg.value - total;
        transferETH(treasury, fee);

        for (uint256 i = 0; i < recipients.length; i++) {
            transferETH(recipients[i], amounts[i]);
        }
        emit SendSuccess(msg.sender);
    }

    function sendERC20(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256 total,
        address token
    ) public payable override {
        checkLen(recipients.length, amounts.length);
        transferETH(treasury, msg.value);
        IERC20 ERC20Token = IERC20(token);

        // Check isAllowed
        uint256 allowance = ERC20Token.allowance(msg.sender, address(this));
        require(allowance >= total, "ERC20: insufficient allowance");

        for (uint256 i = 0; i < recipients.length; i++) {
            ERC20Token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
        emit SendSuccess(msg.sender);
    }

    function sendERC1155(
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address token,
        bytes calldata data
    ) public payable override {
        checkLen(recipients.length, tokenIds.length);
        checkLen(recipients.length, amounts.length);
        transferETH(treasury, msg.value);
        IERC1155 ERC1155Token = IERC1155(token);

        // Check isAllowed
        bool isAllowed = ERC1155Token.isApprovedForAll(
            msg.sender,
            address(this)
        );
        require(isAllowed, "ERC1155: operator is not approved");

        for (uint256 i = 0; i < recipients.length; i++) {
            ERC1155Token.safeTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i],
                amounts[i],
                data
            );
        }
        emit SendSuccess(msg.sender);
    }

    function sendERC721(
        address[] calldata recipients,
        uint256[] calldata tokenIds,
        address token
    ) public payable override {
        checkLen(recipients.length, tokenIds.length);
        transferETH(treasury, msg.value);
        IERC721 ERC721Token = IERC721(token);

        // Check isAllowed
        bool isAllowed = ERC721Token.isApprovedForAll(
            msg.sender,
            address(this)
        );
        require(isAllowed, "ERC721: operator is not approved");

        for (uint256 i = 0; i < recipients.length; i++) {
            ERC721Token.safeTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i]
            );
        }
        emit SendSuccess(msg.sender);
    }

    function transferETH(address recipient_, uint256 amount) private {
        address payable recipient = payable(recipient_);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IMultisender).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }

    // utils
    function checkLen(uint256 leftLength, uint256 rightLength) public pure {
        require(leftLength == rightLength, "left right length not match");
    }
}
