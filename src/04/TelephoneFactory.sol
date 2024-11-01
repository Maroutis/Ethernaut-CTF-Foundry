// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "../Level.sol";
import "./Telephone.sol";

contract TelephoneFactory is Level {
    function createInstance(address _player) public payable override returns (address) {
        _player;
        return address(new Telephone());
    }

    function validateInstance(address payable _instance,  address _player) public view override returns (bool) {
        Telephone instance = Telephone(_instance);
        return instance.owner() == _player;
    }
}
