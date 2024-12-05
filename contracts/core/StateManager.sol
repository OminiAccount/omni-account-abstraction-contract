// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

contract StateManager {
    struct State {
        bytes32 stateRoot;
        bytes32 accInputRoot;
    }

    // State root mapping
    // BatchNum --> state root
    mapping(uint64 => State) public batchNumToState;

    // Last batch verified by the aggregators
    uint64 public lastVerifiedBatch;

    function updateState(
        uint64 batchNum,
        bytes32 stateRoot,
        bytes32 accInputRoot
    ) internal {
        State memory state = State(stateRoot, accInputRoot);
        batchNumToState[batchNum] = state;
    }

    function updateLastVerifiedBatch(uint64 batchNums) internal {
        lastVerifiedBatch += batchNums;
    }
}