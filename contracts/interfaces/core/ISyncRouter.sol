// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

import "./BaseStruct.sol";

interface ISyncRouter is BaseStruct {
    function fetchOmniMessageFee(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee,
        PackedUserOperation[] calldata userOperations
    ) external view returns (uint256);

    function sendOmniMessage(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee, // Amount that the target chain needs to spend to execute userop
        PackedUserOperation[] calldata userOperations
    ) external payable;

    function fetchUserOmniMessageFee(
        CrossMessageParams calldata params
    ) external view returns (uint256);

    function sendUserOmniMessage(
        CrossMessageParams calldata params
    ) external payable;
}
