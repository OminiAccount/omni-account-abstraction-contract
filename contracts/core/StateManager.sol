// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;
import "../libraries/Error.sol";
import "../interfaces/core/IVerifier.sol";
import "../interfaces/core/IStateManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StateManager is IStateManager, Ownable {
    // L2 chain identifier
    uint64 private constant FORK_ID = 1;
    // Modulus zkSNARK
    uint256 private constant _RFIELD =
        21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;

    // State root mapping
    // BatchNum --> state root
    mapping(uint64 => State) public batchNumToState;

    // Last batch verified by the aggregators
    uint64 public lastVerifiedBatch;

    address public _entryPoint;
    address private verifier;

    modifier onlyEntryPoint() {
        require(msg.sender == _entryPoint, "only ep");
        _;
    }

    constructor(address anEntryPoint) Ownable(msg.sender) {
        _entryPoint = anEntryPoint;
    }

    function updateEntryPoint(address anEntryPoint) external onlyOwner {
        _entryPoint = anEntryPoint;
    }

    function updateVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function updateState(
        uint64 batchNum,
        bytes32 stateRoot,
        bytes32 accInputRoot
    ) external onlyEntryPoint {
        State memory state = State(stateRoot, accInputRoot);
        batchNumToState[batchNum] = state;
    }

    function updateLastVerifiedBatch(uint64 batchNums) external onlyEntryPoint {
        lastVerifiedBatch += batchNums;
    }

    function verifyProof(
        bytes calldata proof,
        uint64 _lastVerifiedBatch,
        uint64 newBatchNumber,
        bytes32 newStateRoot,
        bytes32 newAccInputHash
    ) external view returns (bool) {
        bytes memory snarkHashBytes = getInputSnarkBytes(
            _lastVerifiedBatch,
            newBatchNumber,
            batchNumToState[_lastVerifiedBatch].accInputRoot,
            newAccInputHash,
            batchNumToState[_lastVerifiedBatch].stateRoot,
            newStateRoot
        );

        (
            uint256[2] memory pA,
            uint256[2][2] memory pB,
            uint256[2] memory pC
        ) = abi.decode(proof, (uint256[2], uint256[2][2], uint256[2]));

        return
            IVerifier(verifier).verifyProof(
                pA,
                pB,
                pC,
                [uint256(sha256(snarkHashBytes)) % _RFIELD] // Calulate the snark input
            );
    }

    /**
     * @notice Function to calculate the input snark bytes
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param oldStateRoot State root before batch is processed
     * @param newStateRoot New State root once the batch is processed
     */
    function getInputSnarkBytes(
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 oldAccInputHash,
        bytes32 newAccInputHash,
        bytes32 oldStateRoot,
        bytes32 newStateRoot
    ) private view returns (bytes memory) {
        // sanity checks

        if (initNumBatch != 0 && oldAccInputHash == bytes32(0)) {
            revert OldAccInputHashDoesNotExist();
        }

        if (newAccInputHash == bytes32(0)) {
            revert NewAccInputHashDoesNotExist();
        }

        // Check that new state root is inside goldilocks field
        // if (!checkStateRootInsidePrime(uint256(newStateRoot))) {
        //     revert NewStateRootNotInsidePrime();
        // }

        return
            abi.encodePacked(
                0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
                oldStateRoot,
                oldAccInputHash,
                initNumBatch,
                uint64(block.chainid),
                FORK_ID,
                newStateRoot,
                newAccInputHash,
                bytes32(0),
                finalNewBatch
            );
    }
}
