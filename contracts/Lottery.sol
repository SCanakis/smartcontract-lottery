// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// Imports for VRF
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
// import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Lottery is VRFV2PlusWrapperConsumerBase, ConfirmedOwner{

    // off-chain events that will be caught by Wrapper
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }

    // A map of all requests by their requestId
    mapping(uint256 => RequestStatus) public s_requests;

    // past request Id
    uint256[] public requestIds;
    uint256 public lastRequestId;


    // Gas limit for callback fulfillRandomWords
    uint32 public callbackGasLimit;
    // How many block confirmation the VRF servie waits before fulfilling request. The default is 3 but can be higher if you want more secuirty guarantees.
    uint16 public requestConfirmations = 3;
    // num of words requested
    uint32 public numWords = 2;

    // Address LINK
    // address public linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    
    // address WRAPPER
    address public wrapperAddress = 0x195f15F2d49d693cE265b4fB0fdDbE15b1850Cc1;


    address[] public participants;
    // address public owner;
    address public winner;

    AggregatorV3Interface public priceFeed;
    uint256 public dollarPrice;

    enum LotteryState { OPEN, CLOSED, PROCESSING}
    LotteryState public currentState;

    
    // Initalizes ConfirmedOwner, Wrapper, and Aggregator

    constructor (address _priceFeed, uint256 _dollarPrice, uint32 _gasLimit, address _wrapperAddress) ConfirmedOwner(msg.sender) VRFV2PlusWrapperConsumerBase(_wrapperAddress) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        dollarPrice = _dollarPrice;
        callbackGasLimit = _gasLimit;
    }

    function requestRandomWord() internal onlyOwner returns (uint256){
        bytes memory extraArgs = VRFV2PlusClient._argsToBytes(
            VRFV2PlusClient.ExtraArgsV1({nativePayment : true})
        );
        uint256 requestId;
        uint256 reqPrice;

        (requestId, reqPrice) = requestRandomnessPayInNative(
            callbackGasLimit,
            requestConfirmations,
            numWords,
            extraArgs
        );
        s_requests[requestId] = RequestStatus({
            paid: reqPrice,
            randomWords : new uint256[](0),
            fulfilled : false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(currentState == LotteryState.PROCESSING, "Lottery is not in the correct state");

        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );

        // Find Winner
        uint256 winnerIndex = _randomWords[0] % participants.length;
        winner = participants[winnerIndex];
        

        // Resets
        currentState = LotteryState.CLOSED;

        // Transfers Funds to winner
        payable(winner).transfer(address(this).balance);
    }

    function getRequestStatus (uint256 _requestId) external view returns(uint256 paid, bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }


    function openLottery() public onlyOwner {
        currentState = LotteryState.OPEN;
    }

    function endLottery() public onlyOwner {
        currentState = LotteryState.PROCESSING;
        requestRandomWord();

    }


    function enterLottery() public payable{
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