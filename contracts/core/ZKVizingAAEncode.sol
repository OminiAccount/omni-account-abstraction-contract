// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
import {BaseStruct} from "../interfaces/BaseStruct.sol";
contract ZKVizingAAEncode is BaseStruct {

    function batchEncodeCrossHookMessageParams(
        CrossHookMessageParams[] calldata paramsGroup
    ) external view returns (bytes memory bytesCrossHookMessageParamsGroup) {
        bytesCrossHookMessageParamsGroup = abi.encode(paramsGroup);
    }

    function encodeCrossHookMessageParams(
        CrossHookMessageParams calldata params
    ) external view returns (bytes memory bytesCrossHookMessageParams) {
        bytesCrossHookMessageParams = abi.encode(params);
    }

    function encodeCrossETHParams(
        CrossETHParams calldata params
    ) external view returns (bytes memory bytesCrossETHAmount) {
        bytesCrossETHAmount = abi.encode(params);
    }

    function encodeV2SwapParams(
        V2SwapParams calldata params
    ) external view returns (bytes memory v2SwapMessageBytes) {
        v2SwapMessageBytes = abi.encode(params);
    }

    function encodeV3SwapParams(
        V3SwapParams calldata params
    ) external view returns (bytes memory v3SwapMessageBytes) {
        v3SwapMessageBytes = abi.encode(params);
    }

    function encodeCrossV2SwapParams(
        CrossV2SwapParams calldata params
    ) external view returns (bytes memory crossV2MessageBytes) {
        crossV2MessageBytes = abi.encode(params);
    }

    function encodeCrossV3SwapParams(
        CrossV2SwapParams calldata params
    ) external view returns (bytes memory crossV3MessageBytes) {
        crossV3MessageBytes = abi.encode(params);
    }
}
