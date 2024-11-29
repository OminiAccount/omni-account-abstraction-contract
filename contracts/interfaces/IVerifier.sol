// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.23;

/**
 * @dev Define interface verifier
 */
interface IVerifier {
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[1] calldata _pubSignals
    ) external view returns (bool);
}
