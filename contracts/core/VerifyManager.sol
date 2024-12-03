// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {ISP1Verifier} from "../../interfaces/zkaa/ISP1Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VerifyManager is Ownable {
    /// @notice The address of the SP1 verifier contract.
    /// @dev This can either be a specific SP1Verifier for a specific version, or the
    ///      SP1VerifierGateway which can be used to verify proofs for any version of SP1.
    ///      For the list of supported verifiers on each chain, see:
    ///      https://github.com/succinctlabs/sp1-contracts/tree/main/contracts/deployments
    address public verifier;

    /// @notice The verification key for the AA program.
    bytes32 public aaProgramVKey;

    constructor(address _verifier, bytes32 _aaProgramVKey) Ownable(msg.sender) {
        verifier = _verifier;
        aaProgramVKey = _aaProgramVKey;
    }

    function updateVKey(bytes32 _aaProgramVKey) external onlyOwner {
        aaProgramVKey = _aaProgramVKey;
    }

    /// @notice The entrypoint for verifying the proof of an AA.
    /// @param _proofBytes The encoded proof.
    /// @param _publicValues The encoded public values.
    function verifyProof(
        bytes calldata _publicValues,
        bytes calldata _proofBytes
    ) public view {
        ISP1Verifier(verifier).verifyProof(
            aaProgramVKey,
            _publicValues,
            _proofBytes
        );
    }
}
