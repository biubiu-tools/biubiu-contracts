// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceOracle {
    function latestAnswer() external view returns (uint256 price);
}

contract PriceOracleProxy is Ownable {
    address public priceOracle;

    constructor(address po) {
        priceOracle = po;
    }

    function latestAnswer() public view returns (uint256) {
        return IPriceOracle(priceOracle).latestAnswer();
    }

    function updatePriceOracle(address po) public onlyOwner {
        require(
            IPriceOracle(po).latestAnswer() > 0,
            "Invalid price oracle address"
        );
        priceOracle = po;
    }
}
