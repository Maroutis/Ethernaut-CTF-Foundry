// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Level} from "../src/Level.sol";

abstract contract BaseTest is Test {
    address public ethernaut;
    address internal levelFactory;
    HelperConfig public config;
    address payable instance;

    address public owner = makeAddr("Owner");
    address player = makeAddr("Player");

    function setUp() public virtual {
        require(address(levelFactory) != address(0), "level not setup");
    }

    function runLevel() public {

        // run the exploit
        exploitLevel();

        // verify the exploit
        checkSuccess();
    }

    function exploitLevel() internal virtual {
        /* IMPLEMENT YOUR EXPLOIT */
    }

    function checkSuccess() internal {
        /* CHECK SUCCESS */
        vm.startPrank(player);
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        assertTrue(completed, "Solution is not solving the level");

        vm.stopPrank();
    }
}
