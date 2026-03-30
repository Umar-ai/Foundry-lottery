// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock } from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import { LinkToken } from "../test/mocks/LinkToken.sol";

abstract contract CodeConstants is Script {
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
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
        uint256 subscriptionId;
        uint32 callbackgaslimit;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainid => NetworkConfig) public networkConfigs;

    constructor() {
        // Initialize the mapping with Sepolia defaults immediately
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
    }

    /* * NEW FUNCTION: This allows your DeployRaffle script to save
     * the generated subscriptionId back into the contract state.
     */
    function setConfig(uint256 chainid, NetworkConfig memory networkConfig) public {
        networkConfigs[chainid] = networkConfig;
    }

    function ChooseNetworkConfigByChainId(uint256 chainid) public returns (NetworkConfig memory) {
        // Check storage first. If subscriptionId was updated, it will be here.
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

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkEthConfig) {
        uint256 subId = vm.envOr("VRF_SUB_ID", uint256(0));
        return sepoliaNetworkEthConfig = NetworkConfig({
            entrancefee: 0.01 ether,
            lotteryinterval: 30,
            vrfCordinatoraddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: subId, // Starts at 0, updated via setConfig later
            callbackgaslimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0xBcbDD48EFA5bbEF2D11179bB8F6C3Bdb0aD5Be74
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Check to see if we set an active network config
        if (localNetworkConfig.vrfCordinatoraddress != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken link = new LinkToken();
        uint256 subscriptionId = vrfCoordinatorV2_5Mock.createSubscription();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entrancefee: 0.01 ether,
            lotteryinterval: 30,
            vrfCordinatoraddress: address(vrfCoordinatorV2_5Mock),
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // doesn't really matter
            subscriptionId: subscriptionId,
            callbackgaslimit: 500000, // 500,000 gas
            link: address(link),
            account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });
        vm.deal(localNetworkConfig.account, 100 ether);
        return localNetworkConfig;
    }
}
