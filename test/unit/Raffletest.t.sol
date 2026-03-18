// SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { deployRaffle } from "../../script/deployRaffle.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Raffle } from "src/Raffle.sol";

contract Raffletest is Test {
    Raffle public raffle;
    HelperConfig public helperconfig;
    uint256 entrancefee;
    uint256 lotteryinterval;
    address vrfCordinatoraddress;
    bytes32 keyHash;
    uint256 subscriptionid;
    uint32 callbackgaslimit;

    event RaffleEntered(address indexed player);
    event RaffleWinnerPicked(address indexed winner);

    address public NEW_PLAYER = makeAddr("newUser");
    uint256 public constant STARTING_BALANCE = 10 ether;
    uint256 public constant ENTRACE_FEE = 1 ether;
    uint256 public constant INTERVAL = 30;

    function setUp() public {
        deployRaffle deployer = new deployRaffle();
        (raffle, helperconfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();
        entrancefee = config.entrancefee;
        lotteryinterval = config.lotteryinterval;
        vrfCordinatoraddress = config.vrfCordinatoraddress;
        keyHash = config.keyHash;
        subscriptionid = config.subscriptionId;
        callbackgaslimit = config.callbackgaslimit;
        vm.deal(NEW_PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitialStateIsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenMinimumEntraceFeesIsNotPaid() public {
        vm.prank(NEW_PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughEntraceFee.selector);
        raffle.enterRaffle();
    }

    function testRafflePlayerArrayIsWorking() public {
        vm.prank(NEW_PLAYER);
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        assert(raffle.getRaffleParticipantsArray().length >= 1);
    }

    function testIsParticipantAddedInTheParticipantArray() public {
        vm.prank(NEW_PLAYER);
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        address player = raffle.getPlayerByIndex(0);
        assertEq(player, NEW_PLAYER);
    }

    function testEnterRaffleEmitEvent() public {
        vm.prank(NEW_PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(NEW_PLAYER);

        raffle.enterRaffle{ value: ENTRACE_FEE }();
    }

    function testDoesnotAllowPlayerToEnterRaffleWhileRaffleIsCalculating() public {
        //arrange
        vm.prank(NEW_PLAYER);
        //act
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(NEW_PLAYER);
        raffle.enterRaffle{ value: ENTRACE_FEE }();
    }

    function testCheckUpKeepReturnFalsesWhenEnoughTimeIsNotPassed() public {
        //arragne
        vm.prank(NEW_PLAYER);
        //act
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        (bool isCheckUpKeepPassed,) = raffle.checkUpkeep("");
        //assert
        assert(!isCheckUpKeepPassed);
    }

    function testCheckUpKeepReturnsFalseWhenIfRaffleIsNotOpen() public {
        //arrange
        vm.prank(NEW_PLAYER);
        //act
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        (bool isPerformUpNeeded,) = raffle.checkUpkeep("");
        //assert
        assert(!isPerformUpNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenConditionsAreMet() public {
        //arrange
        vm.prank(NEW_PLAYER);
        //act
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        vm.warp(block.timestamp + INTERVAL + 1);
        vm.roll(block.number + 1);
        (bool isPerformUpNeeded,) = raffle.checkUpkeep("");

        //assert
        assertEq(isPerformUpNeeded, true);
    }

    function testPerformUpKeepRevertsWhenEnoughTimeNotPassed() public {
        //arrange
        uint256 currentBalance=0;
        uint256 totalPlayers=0;
        Raffle.RaffleState rState=raffle.getRaffleState();
        vm.prank(NEW_PLAYER);
        //act
        currentBalance=currentBalance+ENTRACE_FEE;
        totalPlayers=1;
        raffle.enterRaffle{ value: ENTRACE_FEE }();
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance, // balance
                totalPlayers, // length
                rState // state
            )
        );
        raffle.performUpkeep("");
    }
}
