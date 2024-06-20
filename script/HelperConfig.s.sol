// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
// import {console} from "forge-std/Test.sol";
import {Level} from "src/Level.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {Statistics} from "src/Statistics.sol";
import {Vm} from "forge-std/Vm.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address ethernaut;
        address payable instance;
        uint256 deployerKey;
    }

    Ethernaut public ethernaut;
    Statistics public statistics;
    address payable public instanceAddress;
    NetworkConfig public activeNetworkConfig;

    // uint256 public DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    address player = makeAddr("Player");
    address public owner = makeAddr("Owner");

    constructor(address _factory) payable {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaInstanceConfig(_factory);
        } else {
            activeNetworkConfig = getOrCreateTestInstanceConfig(_factory);
        }
    }

    function getSepoliaInstanceConfig(address _factory) public payable returns (NetworkConfig memory) {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        ethernaut = Ethernaut(vm.envAddress("ETHERNAUT_SEPOLIA_ADDRESS"));

        // Create a new instance then recover the address from the event
        vm.recordLogs();
        ethernaut.createLevelInstance{value: msg.value}(Level(_factory));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 i = 0;
        while (entries[i].topics[0] != keccak256("LevelInstanceCreatedLog(address,address,address)")) {
            ++i;
        }
        assert(entries[i].topics[0] == keccak256("LevelInstanceCreatedLog(address,address,address)"));
        // event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level);

        instanceAddress = abi.decode(abi.encode(entries[i].topics[2]), (address));

        vm.stopBroadcast();

        return NetworkConfig({
            ethernaut: address(ethernaut),
            instance: instanceAddress,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateTestInstanceConfig(address _factory) public payable returns (NetworkConfig memory) {
        vm.startPrank(owner);
        ethernaut = new Ethernaut();
        statistics = new Statistics();
        statistics.initialize(address(ethernaut));
        ethernaut.setStatistics(address(statistics));
        ethernaut.registerLevel(Level(_factory));
        vm.stopPrank();

        vm.recordLogs();
        vm.startPrank(player);
        ethernaut.createLevelInstance{value: msg.value}(Level(_factory));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 i = 0;
        while (entries[i].topics[0] != keccak256("LevelInstanceCreatedLog(address,address,address)")) {
            ++i;
        }
        assert(entries[i].topics[0] == keccak256("LevelInstanceCreatedLog(address,address,address)"));
        // event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level);

        instanceAddress = abi.decode(abi.encode(entries[i].topics[2]), (address));
        vm.stopPrank();

        // vm.stopBroadcast();

        return NetworkConfig({
            ethernaut: address(ethernaut),
            instance: instanceAddress,
            deployerKey: uint256(bytes32(abi.encodePacked(player)))
        });
    }
}
