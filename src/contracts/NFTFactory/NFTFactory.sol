// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./INFTFactory.sol";
import "./template/ERC20.sol";
import "./template/ERC721.sol";
import "./template/ERC1155.sol";

interface IPriceOracle {
    function latestAnswer() external view returns (uint256 price);
}

contract NFTFactory is INFTFactory {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    mapping(address => Counters.Counter) internal counter;
    mapping(address => mapping(uint256 => TokenCreatedLog)) public logs;
    mapping(string => address) public eipMap;

    address public treasury;

    uint8 public gasCoinDecimals;
    address public priceOracle;
    uint256 public fee;

    constructor(
        address treasury_,
        address priceOracle_,
        uint8 gasCoinDecimals_,
        uint256 fee_
    ) {
        treasury = treasury_;
        gasCoinDecimals = gasCoinDecimals_;
        priceOracle = priceOracle_;
        fee = fee_;
        eipMap["ERC20"] = address(new ERC20Token());
        eipMap["ERC721"] = address(new ERC721Token());
        eipMap["ERC1155"] = address(new ERC1155Token());
    }

    function createToken(
        string memory eip,
        string memory name,
        string memory symbol,
        bytes[] memory data
    ) public payable returns (address newTokenAddr) {
        IToken template = IToken(eipMap[eip]);
        require(compareStrings(eip, template.eip()), "Invalid eip");

        require(
            msg.value >=
                fee.mul(10 ** gasCoinDecimals).div(
                    IPriceOracle(priceOracle).latestAnswer()
                ),
            "createToken: Insufficient amount"
        );

        if (address(this).balance > 10 ** 17) {
            transferETH(treasury, address(this).balance);
        }

        // create
        newTokenAddr = Clones.clone(eipMap[eip]);

        // init
        IToken newToken = IToken(newTokenAddr);
        newToken.init(
            msg.sender,
            string(
                abi.encodePacked(
                    name,
                    " \u26A0\uFE0F\u26A0\uFE0F Test token, no real value."
                )
            ),
            symbol,
            data
        );

        uint256 idx = counter[msg.sender].current();
        TokenCreatedLog memory log = TokenCreatedLog({
            eip: eip,
            tokenAddr: newTokenAddr,
            createdAt: block.timestamp
        });

        logs[msg.sender][idx] = log;
        counter[msg.sender].increment();
        emit TokenCreated(newTokenAddr, eip);
    }

    function queryLogsCount(
        address user
    ) public view override returns (uint256) {
        return counter[user].current();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(INFTFactory).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }

    // utils
    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function transferETH(address recipient_, uint256 amount) private {
        address payable recipient = payable(recipient_);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}
