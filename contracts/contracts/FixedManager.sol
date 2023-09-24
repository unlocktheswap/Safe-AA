// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {SafeRootAccess, SafeTransaction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";

contract FixedManager is ISafeProtocolManager{

    function executeTransaction(ISafe safe, SafeTransaction calldata transaction) external returns (bytes[] memory data) {
        return data;
    }

    function executeRootAccess(ISafe safe, SafeRootAccess calldata rootAccess) external returns (bytes memory data) {
        return data;
    }
}