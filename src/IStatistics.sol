// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IStatistics {
    function saveNewLevel(address level) external;

    function createNewInstance(address instance, address level, address player) external;

    function submitFailure(address instance, address level, address player) external;

    function submitSuccess(address instance, address level, address player) external;
}
