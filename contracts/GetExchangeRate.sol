// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract GetExchangeRate {
    mapping(string => AggregatorV3Interface) internal dataFeeds;

    constructor() {
        // Sepolia
        dataFeeds["ETH"] = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        dataFeeds["USDC"] = AggregatorV3Interface(
            0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
        );
        dataFeeds["DAI"] = AggregatorV3Interface(
            0x14866185B1962B63C3Ea9E03Bc1da838bab34C19
        );

        // Mumbai
        dataFeeds["MATIC"] = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        dataFeeds["USDT"] = AggregatorV3Interface(
            0x92C09849638959196E976289418e5973CC96d645
        );
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer(
        string memory _symbol
    ) public view returns (int, uint8) {
        // prettier-ignore
        (,int answer,,,) = dataFeeds[_symbol].latestRoundData();
        uint8 decimals = dataFeeds[_symbol].decimals();
        return (answer, decimals);
    }
}
