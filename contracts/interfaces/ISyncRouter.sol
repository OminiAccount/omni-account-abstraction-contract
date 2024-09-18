// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

import {MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";

interface ISyncRouter {
    function quote(
        uint32[] memory _dstEids,
        bytes memory encodedMessage,
        bytes calldata _extraSendOptions,
        bool _payInLzToken
    ) external view returns (MessagingFee memory totalFee);

    function send(
        uint32[] memory _dstEids,
        bytes memory _encodedMessage,
        bytes calldata _extraSendOptions, // gas settings for A -> B
        address payable beneficiary
    ) external payable;
}
