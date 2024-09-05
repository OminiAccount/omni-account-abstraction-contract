// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

import {OApp, MessagingFee, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IEntryPoint.sol";

import "forge-std/console.sol";

contract SyncRouter is OApp, OAppOptionsType3 {
    address public entryPoint;
    /// @notice Last received message data.
    bytes public data = "";

    /// @notice Message types that are used to identify the various OApp operations.
    /// @dev These values are used in things like combineOptions() in OAppOptionsType3 (enforcedOptions).
    uint16 public constant SEND = 1;

    /// @notice Emitted when a encodedMessage is received from another chain.
    event MessageReceived(
        bytes32 encodedMessageHash,
        uint32 senderEid,
        bytes32 sender
    );

    /// @notice Emitted when a encodedMessage is sent to another chain (A -> B).
    event MessageSent(bytes32 encodedMessageHash, uint32 dstEid);

    /// @dev Revert with this error when an invalid message type is used.
    error InvalidMsgType();

    modifier onlyEntryPoint() {
        require(msg.sender == entryPoint, "NEQEP");
        _;
    }

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _endpoint The LayerZero endpoint for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     */
    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(msg.sender) {}

    function updateEntryPoint(address _entryPoint) external onlyOwner {
        entryPoint = _entryPoint;
    }

    function _payNative(
        uint256 _nativeFee
    ) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @notice Returns the estimated messaging fee for a given message.
     * @param _dstEids Destination endpoint ID array where the message will be batch sent.
     * @param encodedMessage The encoded message.
     * @param _extraSendOptions Extra gas options for receiving the send call (A -> B).
     * Will be summed with enforcedOptions, even if no enforcedOptions are set.
     * @param _payInLzToken Boolean flag indicating whether to pay in LZ token.
     * @return totalFee The estimated messaging fee for sending to all pathways.
     */
    function quote(
        uint32[] memory _dstEids,
        bytes memory encodedMessage,
        bytes calldata _extraSendOptions,
        bool _payInLzToken
    ) public view returns (MessagingFee memory totalFee) {
        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory options = combineOptions(
                _dstEids[i],
                SEND,
                _extraSendOptions
            );
            MessagingFee memory fee = _quote(
                _dstEids[i],
                encodedMessage,
                options,
                _payInLzToken
            );
            totalFee.nativeFee += fee.nativeFee;
            totalFee.lzTokenFee += fee.lzTokenFee;
        }
    }

    function send(
        uint32[] memory _dstEids,
        bytes memory _encodedMessage,
        bytes calldata _extraSendOptions, // gas settings for A -> B
        address payable beneficiary
    ) external payable onlyEntryPoint {
        // Calculate the total messaging fee required.
        MessagingFee memory totalFee = quote(
            _dstEids,
            _encodedMessage,
            _extraSendOptions,
            false
        );
        require(msg.value >= totalFee.nativeFee, "Insufficient fee provided");

        uint256 totalNativeFeeUsed = 0;
        uint256 remainingValue = msg.value;

        for (uint i = 0; i < _dstEids.length; i++) {
            bytes memory options = combineOptions(
                _dstEids[i],
                SEND,
                _extraSendOptions
            );
            MessagingFee memory fee = _quote(
                _dstEids[i],
                _encodedMessage,
                options,
                false
            );

            totalNativeFeeUsed += fee.nativeFee;
            remainingValue -= fee.nativeFee;

            // Ensure the current call has enough allocated fee from msg.value.
            require(
                remainingValue >= 0,
                "Insufficient fee for this destination"
            );

            _lzSend(_dstEids[i], _encodedMessage, options, fee, beneficiary);

            emit MessageSent(keccak256(_encodedMessage), _dstEids[i]);
        }
    }

    /**
     * @notice Internal function to handle receiving messages from another chain.
     * @dev Decodes and processes the received message based on its type.
     * @param _origin Data about the origin of the received message.
     * @param message The received message content.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*guid*/,
        bytes calldata message,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        // bytes memory _data = abi.decode(message, (string));
        data = message;

        IEntryPoint(entryPoint).syncBatch(message);

        emit MessageReceived(
            keccak256(message),
            _origin.srcEid,
            _origin.sender
        );
    }
}
