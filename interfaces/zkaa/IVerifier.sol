// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.24;

/**
 * @dev Define interface verifier
 */
interface IVerifier {
    function verifyProof(
        bytes32[24] calldata proof,
        uint256[1] calldata pubSignals
    ) external view returns (bool);
}