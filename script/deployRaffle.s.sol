// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";
import { CreateSubscription, FundSubscription, AddConsumer } from "script/Interaction.s.sol";

contract deployRaffle is Script {
    function run() public { }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCordinatoraddress) = createSubscription.createSubscription(config.vrfCordinatoraddress, config.account);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.subscriptionId, config.vrfCordinatoraddress, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entrancefee, config.lotteryinterval, config.vrfCordinatoraddress, config.keyHash, config.subscriptionId, config.callbackgaslimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsume(address(raffle), config.vrfCordinatoraddress, config.subscriptionId, config.account);
        return (raffle, helperConfig);
    }
}
