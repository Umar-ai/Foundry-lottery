// SPDX-License-Identifier:UNLICENSE
pragma solidity ^0.8.19;

import { Script, console } from "forge-std/Script.sol";
import { HelperConfig, CodeConstants } from "script/HelperConfig.s.sol";
import { VRFCoordinatorV2_5Mock } from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "../test/mocks/LinkToken.sol";
import { DevOpsTools } from "lib/foundry-devops/src/DevOpsTools.sol";
import { Raffle } from "../src/Raffle.sol";

contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig config = new HelperConfig();
        address vrfAddress = config.getConfig().vrfCordinatoraddress;
        address account = config.getConfig().account;
        (uint256 subId, address vrfMockAddress) = createSubscription(vrfAddress, account);
        return (subId, vrfMockAddress);
    }

    function createSubscription(address vrfCoordinatorV2_5, address _account) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(_account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subId, vrfCoordinatorV2_5);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig config = new HelperConfig();
        uint256 subId = config.getConfig().subscriptionId;
        address vrfCoordinatorAddress = config.getConfig().vrfCordinatoraddress;
        address linkToken = config.getConfig().link;
        address account = config.getConfig().account;
        fundSubscription(subId, vrfCoordinatorAddress, linkToken, account);
    }

    function fundSubscription(uint256 _subId, address _vrfCoordinatorAddress, address _linkToken, address _account) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinatorAddress).fundSubscription(_subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(_account);
            LinkToken(_linkToken).transferAndCall(_vrfCoordinatorAddress, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address _mostRecentDeployedContract) public {
        HelperConfig config = new HelperConfig();
        uint256 subId = config.getConfig().subscriptionId;
        address vrfCoordinatorAddress = config.getConfig().vrfCordinatoraddress;
        address account = config.getConfig().account;
        addConsume(_mostRecentDeployedContract, vrfCoordinatorAddress, subId, account);
    }

    function addConsume(address contractToAddToVrf, address _vrfCoordinatorAddress, uint256 _subId, address _account) public {
        vm.startBroadcast(_account);
        VRFCoordinatorV2_5Mock(_vrfCoordinatorAddress).addConsumer(_subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentDeployedContract = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentDeployedContract);
    }
}
