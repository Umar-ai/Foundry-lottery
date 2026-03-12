// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { VRFConsumerBaseV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import { VRFV2PlusClient } from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEntraceFee();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    error Raffle__UpKeepNotNeeded(uint256 balance, uint256 length, uint256 state);

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_entrancefee;
    uint256 private immutable i_subscriptionid;
    uint32 private immutable i_callbackgaslimit;
    uint256 private immutable i_lotteryInterval;
    address private s_recentwinner;
    uint32 private constant RANDOM_NUMBERS = 1;
    address payable[] private s_players;
    uint256 private s_lasttimestamp;
    RaffleState private s_rafflestate = RaffleState.OPEN;

    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);

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
        i_keyhash = keyHash;
        i_subscriptionid = _subscriptionid;
        i_callbackgaslimit = _callbackgaslimit;
        s_lasttimestamp = block.timestamp;
        s_rafflestate = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        if (s_rafflestate != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        if (msg.value < i_entrancefee) {
            revert Raffle__NotEnoughEntraceFee();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        internal
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isTimePassed = block.timestamp - s_lasttimestamp > i_lotteryInterval;
        bool isOpen = s_rafflestate == RaffleState.OPEN;
        bool isBalanceNotEmpty = address(this).balance > 0;
        bool isPlayersParticipated = s_players.length > 0;

        bool isEnoughTimepassedandHavePlayers = isTimePassed && isOpen && isBalanceNotEmpty && isPlayersParticipated;
        return (isEnoughTimepassedandHavePlayers, "");
    }

    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        (bool success,) = checkUpkeep("");
        if (!success) {
            revert Raffle__UpKeepNotNeeded(address(this).balance, s_players.length, uint256(s_rafflestate));
        }
        s_rafflestate = RaffleState.CALCULATING;
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyhash,
            subId: i_subscriptionid,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackgaslimit,
            numWords: RANDOM_NUMBERS,
            // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({ nativePayment: false }))
        });

        s_vrfCoordinator.requestRandomWords(request);
    }

    function fulfillRandomWords(uint256, uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentwinner = recentWinner;
        s_rafflestate = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lasttimestamp = block.timestamp;

        (bool success,) = recentWinner.call{ value: address(this).balance }("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit RaffleWinnerPicked(s_recentwinner);
    }

    // getters
    function getMinimumAmountToRaffle() external view returns (uint256) {
        return i_entrancefee;
    }

    function getLotteryIntervalGetter() external view returns (uint256) {
        return i_lotteryInterval;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_rafflestate;
    }

    function getRaffleParticipantsArray() external view returns (address payable[] memory) {
        return s_players;
    }

    function getPlayerByIndex(uint256 playerIndex) external view returns (address) {
        return s_players[playerIndex];
    }
}
