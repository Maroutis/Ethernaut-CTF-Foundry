// SPDX-License-Identifier: MIT

pragma solidity 0.5.0;

import {Level} from "./Level-05.sol";

interface IEthernaut {
    struct EmittedInstanceData {
        address player;
        Level level;
        bool completed;
    }

    function createLevelInstance(Level _level) external payable;
    function submitLevelInstance(address payable _instance) external;
}
