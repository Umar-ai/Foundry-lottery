// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnougEntraceFee();
    error Raffle_NotEnoughTimePassed();
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_entrancefee;
    uint256 private immutable i_subscriptionid;
    uint32 private immutable i_callbackgaslimit;
    uint32 private constant RANDOM_NUMBERS = 1;
    address payable[] private s_players;
    uint256 private s_lasttimestamp;
    uint256 private immutable i_lotteryInterval; //!The interval should be in seconds
    event RaffleEntered(address);

    constructor(
        uint256 entrancefee,
        uint256 lotteryinterval,
        address vrfCordinatoraddress,
        bytes32 keyHash,
        uint256 _subscriptionid,
        uint32 _callbackgaslimit
    ) VRFConsumerBaseV2Plus(vrfCordinatoraddress) {
        i_entrancefee = entrancefee;
        i_lotteryInterval = lotteryinterval;
        s_lasttimestamp = block.timestamp;
        i_keyhash = keyHash;
        i_subscriptionid = _subscriptionid;
        i_callbackgaslimit = _callbackgaslimit;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entrancefee) {
            revert Raffle__NotEnougEntraceFee();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    //1.pick a random number
    //2.pick a player based on the random number
    //3.function must run automatically
    function ChooseWinner() public {
        if ((block.timestamp - s_lasttimestamp) < i_lotteryInterval) {
            revert Raffle_NotEnoughTimePassed();
        }
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyhash,
            subId: i_subscriptionid,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackgaslimit,
            numWords: RANDOM_NUMBERS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: false }))
        });

        uint256 requestid = s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    )
        internal
        override
    {
        // Your logic to pick a winner using randomWords[0] goes here
    }

    // getters
    function Minimum_amount_to_raffle() external view returns (uint256) {
        return i_entrancefee;
    }

    function lottery_interval() external view returns (uint256) {
        return i_lotteryInterval;
    }
}
