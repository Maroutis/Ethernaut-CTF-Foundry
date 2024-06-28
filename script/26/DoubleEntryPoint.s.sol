// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DoubleEntryPoint, Forta, IDetectionBot} from "../../src/26/DoubleEntryPoint.sol";
import {DoubleEntryPointFactory} from "src/26/DoubleEntryPointFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract DoubleEntryPointExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL26_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new DoubleEntryPointFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        DoubleEntryPoint instanceContract = DoubleEntryPoint(instance);

        // Create the bot and and set it in forta contract
        IDetectionBot bot = IDetectionBot(address(new detectionBotForDoubleEntryPoint(instanceContract.cryptoVault(), instanceContract.forta())));
        instanceContract.forta().setDetectionBot(address(bot));

        // DONE !


        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}

contract detectionBotForDoubleEntryPoint {
    address vault;
    Forta forta;

    constructor (address _vault, Forta _forta) {
        vault = _vault;
        forta = _forta;
    }
    // msgData is encoded like this 
    // cast calldata "delegateTransfer(address,uint256,address)" 0x5B38Da6a701c
    // 568545dCfcB03FcB875f56beddC4 59 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // 0x9cd1a121
    // 0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4
    // 000000000000000000000000000000000000000000000000000000000000003b
    // 0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc4
    // The origin address is at byte 68 of msgData
    // We can just check if the origin is the vault and raiseAlert
    function handleTransaction(address user, bytes calldata msgData) external{
        address origSender;
        assembly {
            // msgData.offset points to the first value of msgData which is the selector of the function delegateTransfer
            origSender := calldataload(add(msgData.offset, 0x44))
        }
        if (origSender == vault) {
            forta.raiseAlert(user);
        }
    }
}
