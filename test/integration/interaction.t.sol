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
import { CreateSubscription,FundSubscription} from "../../script/Interaction.s.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { Raffle } from "src/Raffle.sol";
import { deployRaffle } from "../../script/deployRaffle.s.sol";
import {Vm} from 'forge-std/Vm.sol';

contract RaffleInteractionTest is Test {
    CreateSubscription public  createSubscription;
    FundSubscription public  fundSubscription;
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
        deployRaffle deployer=new deployRaffle();
        (raffle,helperConfig)=deployer.deployContract();
        createSubscription = new CreateSubscription();
        fundSubscription=new FundSubscription();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entrancefee = config.entrancefee;
        lotteryinterval = config.lotteryinterval;
        vrfCordinatoraddress = config.vrfCordinatoraddress;
        keyHash = config.keyHash;
        subscriptionid = config.subscriptionId;
        callbackgaslimit = config.callbackgaslimit;
        account=config.account;
        link=config.link;
    }

    // check the subscriptionid is a nonzero

    function testSubscriptionIdReturnedByCreateSubscriptionFunctionIsNotZero() public {
        uint256 subId;
        (subId,)=createSubscription.createSubscription(vrfCordinatoraddress,account);
        assert(subId!=0);
     }

    function testFundSubscriptionActuallyAddedFundsToTheSubscription()public {
        uint256 oldBalance;
        uint256 newBalance;
        uint256 fundAmount=fundSubscription.getFundAmount();
        uint256 subId;
        (subId,)=createSubscription.createSubscription(vrfCordinatoraddress,account);
        vm.recordLogs();
        fundSubscription.fundSubscription(subId,vrfCordinatoraddress,link,account);
        Vm.Log[] memory entries=vm.getRecordedLogs();
       (oldBalance,newBalance)=abi.decode(entries[0].data,(uint256,uint256));
       assertEq(oldBalance,0);
       assertEq(oldBalance+fundAmount,newBalance);
       assertEq(subscriptionid,0);
    } 

    

}
