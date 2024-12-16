// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

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

library VerifierHelper {
    function getSnarkProof(
        bytes calldata proof
    )
        external
        pure
        returns (
            uint256[2] memory _pA,
            uint256[2][2] memory _pB,
            uint256[2] memory _pC
        )
    {
        (_pA, _pB, _pC) = abi.decode(proof, (uint[2], uint[2][2], uint[2]));
    }
}