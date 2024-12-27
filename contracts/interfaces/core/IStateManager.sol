// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

interface IStateManager {
    struct State {
        bytes32 stateRoot;
        bytes32 accInputRoot;
    }

    function lastVerifiedBatch() external view returns (uint64);

    function batchNumToState(
        uint64 batchNumber
    ) external view returns (bytes32, bytes32);

    function updateState(
        uint64 batchNum,
        bytes32 stateRoot,
        bytes32 accInputRoot
    ) external;

    function updateLastVerifiedBatch(uint64 batchNums) external;

    function verifyProof(
        bytes calldata proof,
        uint64 _lastVerifiedBatch,
        uint64 newBatchNumber,
        bytes32 newStateRoot,
        bytes32 newAccInputHash
    ) external view returns (bool);
}
