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
        // address account = config.getConfig().account;
        (uint256 subId, address vrfMockAddress) = createSubscription(vrfAddress);
        return (subId, vrfMockAddress);
    }

    function createSubscription(address vrfCoordinatorV2_5) public returns (uint256, address) {
        vm.roll(block.number + 1);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();
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
        // address account = config.getConfig().account;
        fundSubscription(subId, vrfCoordinatorAddress, linkToken);
    }

    function fundSubscription(uint256 _subId, address _vrfCoordinatorAddress, address _linkToken) public {
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(_vrfCoordinatorAddress).fundSubscription(_subId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(_linkToken).transferAndCall(_vrfCoordinatorAddress, FUND_AMOUNT, abi.encode(_subId));
            vm.stopBroadcast();
        }
    }

    function getFundAmount() public pure returns (uint256) {
        return FUND_AMOUNT * 100;
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCordinatoraddress;
        // address account = helperConfig.getConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinatorV2_5, subId);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
