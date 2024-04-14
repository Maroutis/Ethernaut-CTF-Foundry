// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../Level.sol";
import "./Token.sol";
import {console, Test} from "forge-std/Test.sol";

contract TokenFactory is Level {
    uint256 supply = 21000000;
    uint256 playerSupply = 20;

    function createInstance(address _player) public payable override returns (address) {
        Token token = new Token(supply);
        token.transfer(_player, playerSupply);
        console.log(_player);
        console.log(token.balanceOf(_player));
        return address(token);
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        Token token = Token(_instance);
        return token.balanceOf(_player) > playerSupply;
    }
}
