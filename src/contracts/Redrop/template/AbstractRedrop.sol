// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IRedrop.sol";
import "../Utils.sol";
import "../guards/IGuard.sol";
import "../IRedropFactory.sol";

interface ITokenLockVault {
    function init(uint256 endedAt_) external;

    function deposit(address token, uint256 amount) external;
}

abstract contract AbstractRedrop is Initializable, IRedrop {
    using Counters for Counters.Counter;

    Counters.Counter public claimCounter;

    address public redropFactory;

    // UGC
    uint256 public totalClaimedUser;
    uint256 public totalClaimedAmount;

    mapping(address => uint256) public userClaim;

    mapping(uint256 => ClaimLog) public claimLogs;

    // get randomness
    mapping(address => uint256) public blockHashesToBeUsed;
    mapping(uint8 => uint256) public ranking;

    address public tokenLockVault;

    function init() public initializer {
        redropFactory = msg.sender;
        IRedropFactory factory = IRedropFactory(redropFactory);
        RedropCreatedLog memory info = factory.getRedropInfo(address(this));
        address tokenLockVaultTemplate = factory.tokenLockVaultTemplate();

        // create
        tokenLockVault = Clones.clone(tokenLockVaultTemplate);
        // init
        ITokenLockVault locker = ITokenLockVault(tokenLockVault);
        locker.init(info.endedAt);
    }

    function eip() public virtual override returns (string memory);

    function request() public virtual override;

    function claim(address referrer) public virtual override;

    function refund() public {
        IRedropFactory factory = IRedropFactory(redropFactory);
        RedropCreatedLog memory info = factory.getRedropInfo(address(this));
        uint256 endedAt = info.endedAt;

        address tokenAddress = info.tokenAddress;
        address sender = info.sender;
        require(
            block.timestamp > endedAt,
            "Refund: Wait for end before refund request."
        );
        transferETH(payable(sender), address(this).balance);
        if (tokenAddress != address(0)) {
            IERC20 erc20Token = IERC20(tokenAddress);
            erc20Token.transfer(sender, erc20Token.balanceOf(address(this)));
        }
    }

    function transferETH(address recipient_, uint256 amount) private {
        address payable recipient = payable(recipient_);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function _beforeClaim() internal returns (RedropCreatedLog memory) {
        IRedropFactory factory = IRedropFactory(redropFactory);
        RedropCreatedLog memory info = factory.getRedropInfo(address(this));
        uint256 startedAt = info.startedAt;
        uint256 endedAt = info.endedAt;
        uint256 maxRecipients = info.maxRecipients;
        address guardAddr = info.guardAddr;

        require(
            startedAt < block.timestamp &&
                block.timestamp < endedAt &&
                totalClaimedUser < maxRecipients,
            "Claim: Not within the activity period."
        );

        require(userClaim[msg.sender] == 0, "Claim: Claimed.");

        // Eligible Check
        IGuard guard = IGuard(guardAddr);
        bool eligible = guard.canAccess(msg.sender);
        require(eligible, "Claim: You're not eligible.");

        return info;
    }

    function _findTheSmallest() internal view returns (uint8 pos, uint256 min) {
        min = claimLogs[ranking[0]].visitorAmount;
        pos = 0;
        for (uint8 i; i < 10; i++) {
            uint256 sn = ranking[i];
            if (claimLogs[sn].visitorAmount <= min) {
                min = claimLogs[sn].visitorAmount;
                pos = i;
            }
        }
    }

    function _transferAmount(
        address tokenAddress,
        uint256 amount,
        address referrer
    ) internal {
        uint256 visitorAmount = 0;
        uint256 referrerAmount = 0;

        if (referrer != address(0)) {
            visitorAmount = amount / 2;
            referrerAmount = amount - visitorAmount;
        }

        if (tokenAddress == address(0)) {
            userClaim[msg.sender] = visitorAmount;
            transferETH(payable(msg.sender), visitorAmount);
            if (referrerAmount > 0) {
                transferETH(referrer, referrerAmount);
            }
        } else {
            IERC20 erc20Token = IERC20(tokenAddress);
            userClaim[msg.sender] = visitorAmount;
            erc20Token.transfer(msg.sender, visitorAmount);

            if (referrerAmount > 0) {
                erc20Token.transfer(referrer, referrerAmount);
            }
        }

        totalClaimedUser = totalClaimedUser + 1;
        totalClaimedAmount = totalClaimedAmount + amount;

        _addLog(msg.sender, referrer, visitorAmount, referrerAmount);
    }

    function _addLog(
        address visitor,
        address referrer,
        uint256 visitorAmount,
        uint256 referrerAmount
    ) internal {
        uint256 idx = claimCounter.current();

        (uint8 pos, uint256 min) = _findTheSmallest();

        if (visitorAmount > min) {
            ranking[pos] = idx;
        }

        ClaimLog memory log = ClaimLog({
            visitor: visitor,
            referrer: referrer,
            visitorAmount: visitorAmount,
            referrerAmount: referrerAmount,
            claimedAt: block.timestamp
        });
        claimLogs[idx] = log;
        claimCounter.increment();
        emit Claimed(address(this), visitor, visitorAmount);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IRedrop).interfaceId ||
            interfaceId == 0x01ffc9a7;
    }

    fallback() external payable {}

    receive() external payable {}
}
