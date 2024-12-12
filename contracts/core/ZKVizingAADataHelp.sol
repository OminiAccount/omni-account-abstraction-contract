// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
import {BaseStruct} from "../interfaces/BaseStruct.sol";
contract ZKVizingAADataHelp is BaseStruct {

    function decodeCrossETHData(bytes memory callData)external view returns(CrossETHParams memory){
        return abi.decode(callData, (CrossETHParams));
    }

    function decodeUniswapV2Data(bytes memory callData)external view returns(V2SwapParams memory){
        return abi.decode(callData, (V2SwapParams));
    }

    function decodeUniswapV3Data(bytes memory callData)external view returns(V3SwapParams memory){
        return abi.decode(callData, (V3SwapParams));
    }

    function decodePackedUserOperationGroup(bytes memory callData)external view returns(PackedUserOperation[] memory){
        return abi.decode(callData, (PackedUserOperation[]));
    }

    function decodeCrossHookMessageParamsData(bytes memory callData)external view returns(CrossHookMessageParams memory){
        return abi.decode(callData, (CrossHookMessageParams));
    }

    function decodeCrossMessageParamsData(bytes memory callData)external view returns(CrossMessageParams memory){
        return abi.decode(callData, (CrossMessageParams));
    }

    function batchDecodeCrossHookMessageParams(bytes[] memory callDatas)external view returns(CrossHookMessageParams[] memory){
        CrossHookMessageParams[] memory crossHookGroup;
        for(uint256 i;i<callDatas.length;i++){
            crossHookGroup[i]=abi.decode(callDatas[i], (CrossHookMessageParams));
        }
        return crossHookGroup;
    }

    function batchDecodeCrossMessageParams(bytes[] memory callDatas)external view returns(CrossMessageParams[] memory){
        CrossMessageParams[] memory crossMessageGroup;
        for(uint256 i;i<callDatas.length;i++){
            crossMessageGroup[i]=abi.decode(callDatas[i], (CrossMessageParams));
        }
        return crossMessageGroup;
    }

    function batchEncodeCrossMessageParams(
        CrossMessageParams[] calldata paramsGroup
    ) external view returns (bytes[] memory) {
        bytes[] memory crossMessageParams=new bytes[](paramsGroup.length);
        for(uint256 i; i<paramsGroup.length;i++){
            crossMessageParams[i]= abi.encode(paramsGroup[i]);
        }
        return crossMessageParams;
    }

    function batchEncodeCrossHookMessageParams(
        CrossHookMessageParams[] calldata paramsGroup
    ) external view returns (bytes[] memory) {
        bytes[] memory crossHookMessageParams=new bytes[](paramsGroup.length);
        for(uint256 i; i<paramsGroup.length;i++){
            crossHookMessageParams[i]= abi.encode(paramsGroup[i]);
        }
        return crossHookMessageParams;
    }
    
    function encodeCrossMessageParams(CrossMessageParams calldata params)external view returns (bytes memory crossMessage) {
        crossMessage = abi.encode(params);
    }

    function encodeCrossHookMessageParams(
        CrossHookMessageParams calldata params
    ) external view returns (bytes memory bytesCrossHookMessageParams) {
        bytesCrossHookMessageParams = abi.encode(params);
    }

    function encodePackedUserOperationGroup(PackedUserOperation[] calldata paramsGroup)external view returns (bytes memory bytesUserOperation){
        bytesUserOperation=abi.encode(paramsGroup);
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
