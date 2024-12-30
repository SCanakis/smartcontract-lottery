// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";



contract Lottery {

    address[] public participants;
    address public owner;
    address public winner;

    AggregatorV3Interface public priceFeed;
    uint256 public dollarPrice;

    enum LotteryState { OPEN, CLOSED, PROCESSING}
    LotteryState currentState;

    constructor (address _priceFeed, uint256 _dollarPrice) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
        dollarPrice = _dollarPrice;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function openLottery() public onlyOwner {
        currentState = LotteryState.OPEN;
    }

    function chooseWinner() public onlyOwner {
        currentState = LotteryState.PROCESSING;
    }


    function enterLotter() public payable{
        require(currentState == LotteryState.OPEN, "Lottery is currently not open!");
        require(msg.value >= getPrice(), "More Eth is required to enter lottery!");
        participants.push(msg.sender);
    }

    function getConversion() public view returns (uint256) {
        (, int answer, , ,) = priceFeed.latestRoundData();
        uint256 price = uint256(answer) * 10 ** 10;
        return price;
    }

    function getPrice() public view returns (uint256) {
        uint256 ethPrice = getConversion(); 
        
        uint256 adjustedDollarPrice = dollarPrice * 10 ** 18;
        uint256 price = (adjustedDollarPrice * 10 ** 18) / ethPrice;
        return price;
    }

}