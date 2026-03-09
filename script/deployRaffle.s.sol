// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";
import { HelperConfig } from "script/HelperConfig.s.sol";

contract deployRaffle is Script {
    function run() public { }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entrancefee,
            config.lotteryinterval,
            config.vrfCordinatoraddress,
            config.keyHash,
            config.subscriptionid,
            config.callbackgaslimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}
