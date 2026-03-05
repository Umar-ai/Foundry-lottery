// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { Raffle } from "../src/Raffle.sol";

contract CounterScript is Script {
    Raffle public raffle;

    function setUp() public { }

    function run() public {
        vm.startBroadcast();

        // raffle = new Raffle();

        vm.stopBroadcast();
    }
}
