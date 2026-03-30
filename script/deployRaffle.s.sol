// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interaction.s.sol";

contract deployRaffle is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (uint256 updatedSubId, address updatedCoordinator) = createSubscription.createSubscription(config.vrfCordinatoraddress);

            // Explicitly update the struct
            config.subscriptionId = updatedSubId;
            config.vrfCordinatoraddress = updatedCoordinator;
            helperConfig.setConfig(block.chainid, config);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.subscriptionId, config.vrfCordinatoraddress, config.link);
        }

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entrancefee, config.lotteryinterval, config.vrfCordinatoraddress, config.keyHash, config.subscriptionId, config.callbackgaslimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCordinatoraddress, config.subscriptionId);
        return (raffle, helperConfig);
    }
}
