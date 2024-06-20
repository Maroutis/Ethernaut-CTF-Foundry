// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MagicNumber} from "src/18/MagicNumber.sol";
import {MagicNumberFactory} from "src/18/MagicNumberFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract MagicNumberExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL18_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new MagicNumberFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory); //0.001 ether required
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // deploy the init bytecode of the contract using the minimal bytecode pattern
        address solver;
        assembly {
            mstore(0x00, 0x600a600c600039600a6000F3602a60005260206000F3)
            solver := create(0, 0x0a, 0x16) // point to position 10 in memory for a length of 22 bytes because mstore pads with leading 0s when storing a value (in a 32 bytes format)
            if iszero(solver) { revert(0, 0) }
        }
        // Update using the newly deployed solver
        MagicNumber(instance).setSolver(solver);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
