// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import {
    VRFCoordinatorV2_5Mock
} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstants is Script {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, CodeConstants {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 entrancefee;
        uint256 lotteryinterval;
        address vrfCordinatoraddress;
        bytes32 keyHash;
        uint256 subscriptionid;
        uint32 callbackgaslimit;
    }
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    function ChooseNetworkConfigByChainId(uint256 chainid) public returns (NetworkConfig memory) {
        if (networkConfigs[chainid].vrfCordinatoraddress != address(0)) {
            return networkConfigs[chainid];
        } else if (chainid == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getConfig() public returns (NetworkConfig memory) {
        return ChooseNetworkConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            entrancefee: 0.01 ether,
            lotteryinterval: 30,
            vrfCordinatoraddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionid: 0,
            callbackgaslimit: 500000
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCordinatoraddress != address(0)) {
            return localNetworkConfig;
        }
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entrancefee: 0.01 ether,
            lotteryinterval: 30,
            vrfCordinatoraddress: address(vrfCordinatorV2_5Mock),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionid: 0,
            callbackgaslimit: 500000
        });
        return localNetworkConfig;
    }
}
