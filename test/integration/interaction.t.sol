//Types of test
//uint
//integration
//fork
//staging

//fuzz test
//stateful fuzz test
//stateless fuzz test

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
import { Test } from "forge-std/Test.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "../../script/Interaction.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Raffle } from "src/Raffle.sol";
import { deployRaffle } from "../../script/deployRaffle.s.sol";
import { Vm } from "forge-std/Vm.sol";

contract RaffleInteractionTest is Test {
    CreateSubscription public createSubscription;
    FundSubscription public fundSubscription;
    AddConsumer public addConsumer;
    HelperConfig helperConfig;
    Raffle public raffle;

    uint256 entrancefee;
    uint256 lotteryinterval;
    address vrfCordinatoraddress;
    bytes32 keyHash;
    uint256 subscriptionid;
    uint32 callbackgaslimit;
    address account;
    address link;

    function setUp() public {
        deployRaffle deployer = new deployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entrancefee = config.entrancefee;
        lotteryinterval = config.lotteryinterval;
        vrfCordinatoraddress = config.vrfCordinatoraddress;
        keyHash = config.keyHash;
        subscriptionid = config.subscriptionId;
        callbackgaslimit = config.callbackgaslimit;
        // account = config.account;
        link = config.link;
    }

    // check the subscriptionid is a nonzero

    function testSubscriptionIdReturnedByCreateSubscriptionFunctionIsNotZero() public {
        uint256 subId;
        (subId,) = createSubscription.createSubscription(vrfCordinatoraddress);
        assert(subId != 0);
    }

    function testFundSubscriptionActuallyAddedFundsToTheSubscription() public {
        uint256 oldBalance;
        uint256 newBalance;
        uint256 fundAmount = fundSubscription.getFundAmount();
        vm.recordLogs();
        fundSubscription.fundSubscription(subscriptionid, vrfCordinatoraddress, link);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        (oldBalance, newBalance) = abi.decode(entries[0].data, (uint256, uint256));
        assertEq(oldBalance + fundAmount, newBalance);
    }

    function testConsumerIdAddedInTheSubscriptionConsumersArray() public {
        // 1. Arrange: Define the consumer address
        address consumerToTest = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;

        // 2. Act: Call the specific logic function, NOT the "UsingConfig" wrapper
        vm.recordLogs();

        // We use the variables already populated in setUp()
        addConsumer.addConsumer(consumerToTest, vrfCordinatoraddress, subscriptionid);

        // 3. Assert
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // We decode the event: SubscriptionConsumerAdded(uint256 subId, address consumer)
        // Note: Ensure index [0] is the correct event in your trace
        (uint256 subId, address consumerId) = abi.decode(entries[0].data, (uint256, address));

        assertEq(consumerId, consumerToTest);
        assertEq(subId, subscriptionid);
    }
}
