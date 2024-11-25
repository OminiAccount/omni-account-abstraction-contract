// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IEntryPoint.sol";

contract SyncRouter is VizingOmni, Ownable {
    error InvalidData();
    mapping(uint64 => address) public mirrorEntryPoint;

    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    address public immutable override selectedRelayer;
    bytes1 public immutable BRIDGE_SEND_MODE = 0x01; //STANDARD_ACTIVATE
    bytes public additionParams = new bytes(0);
    uint24 public defaultGaslimit = 50000;
    uint64 public defaultGasPrice = 1 gwei;

    modifier onlyEntryPoint(uint64 chainId) {
        require(msg.sender == mirrorEntryPoint[chainId], "MEP");
        _;
    }

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _vizingPad The VizingPad for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     */
    constructor(
        address _vizingPad,
        address _owner
    ) VizingOmni(_vizingPad) Ownable(msg.sender) {}

    function setMirrorEntryPoint(
        uint64 chainId,
        address entryPoint
    ) external onlyOwner {
        mirrorEntryPoint[chainId] = entryPoint;
    }

    function fetchOmniMessageFee(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee,
        bytes memory batchsMessage
    ) public view virtual returns (uint256) {
        bytes memory message = abi.encode(batchsMessage);
        bytes memory encodedMessage = _packetMessage(
            BRIDGE_SEND_MODE,
            destContract,
            defaultGaslimit,
            defaultGasPrice,
            message
        );

        return
            LaunchPad.estimateGas(
                destChainUsedFee,
                destChainId,
                additionParams,
                encodedMessage
            );
    }

    function sendOmniMessage(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee, // Amount that the target chain needs to spend to execute userop
        bytes memory batchsMessage
    ) external payable onlyEntryPoint(uint64(block.chainid)) {
        bytes memory message = abi.encode(batchsMessage);

        bytes memory encodedMessage = _packetMessage(
            BRIDGE_SEND_MODE,
            destContract,
            defaultGaslimit,
            defaultGasPrice,
            message
        );

        uint256 gasFee = fetchOmniMessageFee(
            destChainId,
            destContract,
            destChainUsedFee,
            batchsMessage
        );

        require(msg.value >= gasFee + destChainUsedFee);

        // step 4: send Omni-Message 2 Vizing Launch Pad
        LaunchPad.Launch{value: msg.value}(
            minArrivalTime,
            maxArrivalTime,
            selectedRelayer,
            msg.sender,
            destChainUsedFee,
            destChainId,
            additionParams,
            encodedMessage
        );
    }

    // _receiveMessage is Inheritance from VizingOmni
    function _receiveMessage(
        bytes32 messageId,
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual override {
        if (mirrorEntryPoint[srcChainId] != address(uint160(srcContract))) {
            revert InvalidData();
        }
        bytes memory batchsMessage = abi.decode(message, (bytes));

        (
            IEntryPoint.BatchData[] memory batches,
            bytes32[] memory batchHashs
        ) = abi.decode(batchsMessage, (IEntryPoint.BatchData[], bytes32[]));

        IEntryPoint(mirrorEntryPoint[uint64(block.chainid)]).syncBatch(
            batches,
            batchHashs
        );
    }
}
