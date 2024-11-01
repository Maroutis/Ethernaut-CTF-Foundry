// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Level.sol";
import "./Preservation.sol";

contract PreservationFactory is Level {
    address timeZone1LibraryAddress;
    address timeZone2LibraryAddress;

    constructor() {
        timeZone1LibraryAddress = address(new LibraryContract());
        timeZone2LibraryAddress = address(new LibraryContract());
    }

    function createInstance(address _player) public payable override returns (address) {
        _player;
        Preservation instance = new Preservation(timeZone1LibraryAddress, timeZone2LibraryAddress);
        return address(instance);
    }

    function validateInstance(address payable _instance, address _player) public view override returns (bool) {
        Preservation instance = Preservation(_instance);
        return instance.owner() == _player;
    }
}
