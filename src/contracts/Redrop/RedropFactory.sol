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

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

// guards
import "./guards/IGuard.sol";
import "./guards/All.sol";
import "./guards/ERC20Min.sol";
import "./guards/ERC721Holder.sol";
import "./guards/ERC1155Holder.sol";
import "./guards/ETHMin.sol";

// templates
import "./template/IRedrop.sol";
import "./template/Redrop101.sol";
import "./template/Redrop102.sol";
import "./template/Redrop103.sol";

import "./IRedropFactory.sol";
import "./TokenLockVault.sol";

contract RedropFactory is IRedropFactory, Ownable, Multicall {
    using Counters for Counters.Counter;

    // user
    mapping(address => Counters.Counter) internal userCounter;
    mapping(address => mapping(uint256 => address)) public userLogs;

    // all
    mapping(string => Counters.Counter) public counter;
    mapping(string => mapping(uint256 => address)) public logs;

    // detail
    mapping(address => RedropCreatedLog) redropLogs;

    mapping(string => address) public eipMap;
    mapping(string => address) public guardMap;

    address public tokenLockVaultTemplate;

    constructor() {
        eipMap["Redrop101"] = address(new Redrop101());
        eipMap["Redrop102"] = address(new Redrop102());
        eipMap["Redrop103"] = address(new Redrop103());

        guardMap["All"] = address(new All());
        // guardMap["ERC20Min"] = address(new ERC20Min());
        guardMap["ERC721Holder"] = address(new ERC721Holder());
        // guardMap["ERC1155Holder"] = address(new ERC1155Holder());
        guardMap["ETHMin"] = address(new ETHMin());
    }

    function createRedrop(
        string memory eip,
        string memory guardType,
        bytes[] memory guardArgs,
        bytes[] memory redropArgs
    ) public payable override returns (address newRedropAddr) {
        IRedrop template = IRedrop(eipMap[eip]);
        require(Utils.compareStrings(eip, template.eip()), "Invalid eip");

        address guardAddr = guardMap[guardType];

        if (Utils.compareStrings(guardType, "Customize")) {
            guardAddr = Utils.bytesToAddress(guardArgs[0]);
        }
        IGuard guard = IGuard(guardAddr);
        require(
            Utils.compareStrings(guardType, guard.guardType()),
            "Invalid guardType"
        );

        // guard ready
        address realGuardAddr = address(0);
        if (Utils.compareStrings(guardType, "Customize")) {
            realGuardAddr = guardAddr;
        } else {
            // create
            realGuardAddr = Clones.clone(guardAddr);
            // init
            IGuard(realGuardAddr).init(guardArgs);
        }

        // eip ready
        // create
        newRedropAddr = Clones.clone(eipMap[eip]);

        // init
        IRedrop(newRedropAddr).init();

        // user logs
        userLogs[msg.sender][userCounter[msg.sender].current()] = newRedropAddr;
        userCounter[msg.sender].increment();

        // logs
        logs[eip][counter[eip].current()] = newRedropAddr;
        counter[eip].increment();

        // Redrop info
        RedropCreatedLog memory log = RedropCreatedLog({
            eip: eip,
            redropAddr: newRedropAddr,
            createdAt: block.timestamp,
            sender: msg.sender,
            guardAddr: realGuardAddr,
            tokenAddress: Utils.bytesToAddress(redropArgs[0]),
            maxRecipients: Utils.bytesToUint(redropArgs[1]),
            totalAmount: Utils.bytesToUint(redropArgs[2]),
            greetings: Utils.bytesToString(redropArgs[3]),
            startedAt: Utils.bytesToUint(redropArgs[4]),
            endedAt: Utils.bytesToUint(redropArgs[5]),
            dividendToken: Utils.bytesToAddress(redropArgs[6]),
            url: Utils.bytesToString(redropArgs[7]),
            memo: Utils.bytesToString(redropArgs[8])
        });

        redropLogs[newRedropAddr] = log;

        // transfer ETH or ERC20 Token
        address tokenAddress = Utils.bytesToAddress(redropArgs[0]);
        uint256 totalAmount = Utils.bytesToUint(redropArgs[2]);
        if (tokenAddress != address(0)) {
            IERC20 erc20Token = IERC20(tokenAddress);
            uint256 allowance = erc20Token.allowance(msg.sender, address(this));
            uint256 balance = erc20Token.balanceOf(msg.sender);
            require(
                allowance >= totalAmount && balance >= totalAmount,
                "RedropFactory: Insufficient Amount"
            );
            erc20Token.transferFrom(msg.sender, newRedropAddr, totalAmount);
        } else {
            require(
                msg.value >= totalAmount,
                "RedropFactory: Insufficient Amount"
            );
            transferETH(newRedropAddr, msg.value);
        }
        emit RedropCreated(newRedropAddr, eip);
    }

    function getRedropInfo(
        address addr
    ) public view returns (RedropCreatedLog memory) {
        return redropLogs[addr];
    }

    function queryLogsCount(
        address user
    ) public view override returns (uint256) {
        return userCounter[user].current();
    }

    function batchRefund(address[] calldata list) public {
        for (uint256 i = 0; i < list.length; i++) {
            IRedrop redrop = IRedrop(list[i]);
            redrop.refund();
        }
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
            interfaceId == type(IRedropFactory).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }
}
