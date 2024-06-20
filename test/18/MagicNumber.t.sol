// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {MagicNumber} from "../../src/18/MagicNumber.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {MagicNumberFactory} from "src/18/MagicNumberFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract MagicNumberTest is Test, BaseTest {
    MagicNumber public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new MagicNumberFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();

        // Need to recover the deployment address
        instanceContract = MagicNumber(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // This was a good exercise that made me deep dive into the evm. Before doing this I had to do EVM Puzzle challenges which made this ctf easier to solve.
        // The idea is to deploy a minimalistic contract with a runtime code of 10 opcodes or less that returns 42 (0x2a)
        // Since we are deploying a contract that does something. We will call the CREATE opcode somewhere. The rule when creating a contract using CREATE opcode:
        // @note "When the CREATE opcode is executed, only the code returned by the RETURN opcode will be the "runtime code" that will be executed in the future when the deployed contract will be called. The other part of the bytecode is just used once, only for the constructor part." Thus, we need to write two sets of bytecodes :
        // 1- Initialization bytecode (or constructor part): It is responsible for preparing the contract and returning the runtime bytecode
        // 2- Runtime bytecode : This is the actual code run after the contarct creation. In other words, this contains the logic of the contract.

        // Let's forget about the 10 bytes size rule for now. And create a contract that returns 42 when the function whatIsTheMeaningOfLife() is called using only opcodes:

        // The first part is the initialization code :
        // PUSH1 ..   (byte size of the code to copy) This will be determined after coding the second part
        // PUSH1 ..   (byte offset in the code to copy) This will be determined after coding the second part
        // PUSH1 00   (memory position)
        // CODECOPY   (@note Copy part of the current running code in a specific part in memory which means there is no padding before unlike mstore)
        // PUSH1 ..   (size of data to return from memory) This will be determined after coding the second part
        // PUSH1 00   (position in memory)
        // RETURN     (return data from a specific position from memory)

        // The second part is the runtime code that should be returned by the initialization code :
        // PUSH1 00   (byte offset of calldata)
        // CALLDATALOAD
        // PUSH1 e0   (decimal 224)
        // SHR        (we shift the calldata to the right by 28 bytes leaving only the function selector)
        // PUSH4 650500c1     = cast sig "whatIsTheMeaningOfLife()"
        // EQ         (compares if calldata selector is the correct one)
        // PUSH1 0f   jumps to 15 position
        // JUMPI      jumps if correct function selector
        // JUMPDEST
        // PUSH1 2a (42)
        // PUSH1 00
        // MSTORE  (stores it in 1 byte memory) Use mstore because we want the result to be in bytes32 (or uint256)
        // PUSH1 20
        // PUSH1 00
        // RETURN

        // Now that the second part is made, we can calculate the size : 25 bytes and bytes offset from where to copy is 12. The full part is :
        // PUSH1 1a
        // PUSH1 0c
        // PUSH1 00
        // CODECOPY
        // PUSH1 1a
        // PUSH1 00 (since codecopy copies at the start of the memory location without padding)
        // RETURN
        // PUSH1 00
        // CALLDATALOAD
        // PUSH1 e0   (decimal 224)
        // SHR
        // PUSH4 650500c1     = cast sig "whatIsTheMeaningOfLife()"
        // EQ
        // PUSH1 0f   jumps to 15 position
        // JUMPI
        // JUMPDEST
        // PUSH1 2a (42)
        // PUSH1 00
        // MSTORE
        // PUSH1 20
        // PUSH1 00
        // RETURN
        // In full bytecode this would give us : 601a600c600039601a6000F3 + 60003560e01c63650500c114600f575B602a60005260206000F3 or 601a600c600039601a6000F360003560e01c63650500c114600f575B602a60005260206000F3

        // If we wanted to do this right we would have something like this (comparing the signatures of calldata ...). However, the size of the runtime bytecode is 25 which is much more than what we want to have. So we need to do this with minimal functionality. The solution is to directly return the 42 value without doing any checks. A minimal runtime bytecode would look like this :
        // PUSH1 2a
        // PUSH 00
        // MSTORE
        // PUSH1 20
        // PUSH1 00
        // RETURN
        // In bytecode : 602a60005260206000F3
        // This have a size of 10 bytes, exactly what we are looking for! Now all we need is to add an initialization code. There are two ways that we can do this:

        // The first way is similar to our first bytecode which is to use CODECOPY opcode :
        // PUSH1 0a  (size of code to copy)
        // PUSH1 0c  (offset in code to copy, we start copying at the 12th offset right after the return)
        // PUSH1 00
        // CODECOPY
        // PUSH1 0a
        // PUSH1 00 (@note since codecopy copies at the start of the memory location without padding)
        // RETURN
        // In full bytecode this would give us : 600a600c600039600a6000F3 + 602a60005260206000F3 = 600a600c600039600a6000F3602a60005260206000F3

        // The second way is to directly return the runtime bytecode rather than copying it
        // PUSH10 602a60005260206000F3
        // PUSH1 00
        // MSTORE
        // PUSH1 0a
        // PUSH1 16  (@note VERY IMPORTANT! MSTORE stores the value in bytes32 format chunks, which means it pads with zeros to the left if the stored value < 32 bytes. MLOAD on the other hand will shift the value to the left so that there are no preceding zeros before adding to stack). by pushing 16 (22 in dec) we are telling the program to return the value on starting at byte 22.
        // RETURN
        // In full bytecode this would give us : 69602a60005260206000F3600052600a6016F3

        // Both solutions work

        // Now it is time to deploy the bytecode that will create the smart contract

        // Can also use 69602a60005260206000F3600052600a6016F3
        // bytes memory bytecode = hex"600a600c600039600a6000F3602a60005260206000F3";
        uint256 codeSize;
        uint256 value;
        address solver;

        // This code is inspired by the OpenZeppelin Clones utils
        // that is implementing the EIP 1167 that is a standard for deploying
        // minimal bytecode implementation
        // More info ->
        // - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol
        // - https://eips.ethereum.org/EIPS/eip-11
        // Other useful sites :
        // OPCODES and their associated bytecodes -> https://github.com/fvictorio/evm-puzzles/blob/master/src/opcodes.js
        // evm.code for testing a CREATE and CALL for the same contract -> https://www.evm.codes/playground?callValue=8&unit=Wei&callData=&codeType=Bytecode&code=%2736600080373660006000F0604051600080806020945AF1600014601B57FD5B00%27_
        // OPCODES gas costs -> https://github.com/djrtwo/evm-opcode-gas-costs/blob/master/opcode-gas-costs_EIP-150_revision-1e18248_2017-04-12.csv

        assembly {
            mstore(0x00, 0x600a600c600039600a6000F3602a60005260206000F3)
            solver := create(0, 0x0a, 0x16) // point to position 10 in memory for a length of 22 bytes because mstore pads with leading 0s when storing a value (in a 32 bytes format)
            if iszero(solver) { revert(0, 0) }
            codeSize := extcodesize(solver)
        }

        instanceContract.setSolver(solver);

        // Perform a call
        assembly {
            let result := mload(0x40) // Get free memory pointer
            let success := call(gas(), solver, 0, 0, 0, result, 0x20)

            if iszero(success) { revert(0, 0) }

            value := mload(result)
        }

        assert(uint256(value) == uint256(42));
        assert(codeSize == 10);

        vm.stopPrank();
    }
}
