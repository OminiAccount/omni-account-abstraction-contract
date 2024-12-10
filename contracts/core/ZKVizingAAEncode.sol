// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {BaseStruct} from "../interfaces/core/BaseStruct.sol";
library HookLib {
    // function getV2SwapSelector() internal pure returns (bytes4) {
    //     return
    //         bytes4(
    //             keccak256(
    //                 "v2Swap((uint8,uint256,uint256,address[],address,uint256))"
    //             )
    //         );
    // }

    // function getV3SwapSelector() internal pure returns (bytes4) {
    //     return
    //         bytes4(
    //             keccak256(
    //                 "v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))"
    //             )
    //         );
    // }

    function decodeCrossETHMessage(
        bytes memory crossETHMessage
    ) internal pure returns (BaseStruct.CrossETHParams memory params) {
        (params) = abi.decode(crossETHMessage, (BaseStruct.CrossETHParams));
    }

    function decodeV2SwapMessage(
        bytes memory swapMessage
    ) internal pure returns (BaseStruct.V2SwapParams memory params) {
        (params) = abi.decode(swapMessage, (BaseStruct.V2SwapParams));
    }

    function decodeV3SwapMessage(
        bytes memory swapMessage
    ) internal pure returns (BaseStruct.V3SwapParams memory params) {
        (params) = abi.decode(swapMessage, (BaseStruct.V3SwapParams));
    }

    function decodeCrossV2SwapMessage(
        bytes memory crossMessage
    ) internal pure returns (BaseStruct.CrossV2SwapParams memory params) {
        (params) = abi.decode(crossMessage, (BaseStruct.CrossV2SwapParams));
    }

    function decodeCrossV3SwapMessage(
        bytes memory crossMessage
    ) internal pure returns (BaseStruct.CrossV3SwapParams memory params) {
        (params) = abi.decode(crossMessage, (BaseStruct.CrossV3SwapParams));
    }

    function fromCrossV3ToTargetV3SwapParams(
        BaseStruct.CrossV3SwapParams memory crossParams
    ) internal pure returns (BaseStruct.V3SwapParams memory v3SwapParams) {
        v3SwapParams = BaseStruct.V3SwapParams({
            index: crossParams.targetIndex,
            fee: crossParams.targetFee,
            sqrtPriceLimitX96: crossParams.targetSqrtPriceLimitX96,
            tokenIn: address(0),
            tokenOut: crossParams.targetChainTokenOut,
            recipient: crossParams.recipient,
            amountIn: crossParams.amountIn,
            amountOutMinimum: crossParams.amountOutMinimum
        });
    }

    function encodeCrossETHParams(
        BaseStruct.CrossETHParams calldata params
    ) external pure returns (bytes memory crossETHAmount) {
        crossETHAmount = abi.encode(params);
    }

    function encodeV2SwapParams(
        BaseStruct.V2SwapParams calldata params
    ) external pure returns (bytes memory v2SwapMessageBytes) {
        v2SwapMessageBytes = abi.encode(params);
    }

    function encodeV3SwapParams(
        BaseStruct.V3SwapParams calldata params
    ) external pure returns (bytes memory v3SwapMessageBytes) {
        v3SwapMessageBytes = abi.encode(params);
    }

    function encodeCrossV2SwapParams(
        BaseStruct.CrossV2SwapParams calldata params
    ) external pure returns (bytes memory crossV2MessageBytes) {
        crossV2MessageBytes = abi.encode(params);
    }

    function encodeCrossV3SwapParams(
        BaseStruct.CrossV2SwapParams calldata params
    ) external pure returns (bytes memory crossV3MessageBytes) {
        crossV3MessageBytes = abi.encode(params);
    }
}
