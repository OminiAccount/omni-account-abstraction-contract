// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

interface IVerifyManager {
    function verifyProof(
        bytes calldata _publicValues,
        bytes calldata _proofBytes
    ) external view;
}
