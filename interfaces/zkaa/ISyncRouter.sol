// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

interface ISyncRouter {
    function fetchOmniMessageFee(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee,
        bytes memory batchsMessage
    ) external view returns (uint256);

    function sendOmniMessage(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee, // Amount that the target chain needs to spend to execute userop
        bytes memory batchsMessage
    ) external payable;
}
