// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {DoubleEntryPoint, Forta, IDetectionBot} from "../../src/26/DoubleEntryPoint.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DoubleEntryPointFactory} from "src/26/DoubleEntryPointFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract DoubleEntryPointTest is Test, BaseTest {
    DoubleEntryPoint public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new DoubleEntryPointFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = DoubleEntryPoint(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // Create the bot and and set it in forta contract
        IDetectionBot bot = IDetectionBot(address(new detectionBotForDoubleEntryPoint(instanceContract.cryptoVault(), instanceContract.forta())));
        instanceContract.forta().setDetectionBot(address(bot));

        // DONE !

        vm.stopPrank();
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

