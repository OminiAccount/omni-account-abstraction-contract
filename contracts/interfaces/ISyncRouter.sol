// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

interface ISyncRouter {
    function send(
        uint32[] memory _dstEids,
        bytes memory _encodedMessage,
        bytes calldata _extraSendOptions, // gas settings for A -> B
        address payable beneficiary
    ) external payable;
}
