// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
import {BaseStruct} from "../interfaces/BaseStruct.sol";
abstract contract HookSelecter is BaseStruct {

    function callSomeFunction(address target, bytes memory payload) external returns (bool success, bytes memory data) {
        (success, data) = target.call(payload);
        require(success, "Call failed");
    }

    function getV2SwapSelector() internal pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "v2Swap((uint8,uint256,uint256,address[],address,uint256))"
                )
            );
    }

    function getV3SwapSelector() internal pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))"
                )
            );
    }

    function decodeCrossETHMessage(
        bytes memory crossETHMessage
    ) public view returns (CrossETHParams memory params){
        (params) = abi.decode(crossETHMessage, (CrossETHParams));
    }

    function decodeV2SwapMessage(
        bytes memory swapMessage
    ) public view returns (V2SwapParams memory params) {
        (params) = abi.decode(swapMessage, (V2SwapParams));
    }

    function decodeV3SwapMessage(
        bytes memory swapMessage
    ) public view returns (V3SwapParams memory params) {
        (params) = abi.decode(swapMessage, (V3SwapParams));
    }

    function decodeCrossV2SwapMessage(
        bytes memory crossMessage
    ) public view returns (CrossV2SwapParams memory params) {
        (params) = abi.decode(crossMessage, (CrossV2SwapParams));
    }

    function decodeCrossV3SwapMessage(
        bytes memory crossMessage
    ) public view returns (CrossV3SwapParams memory params) {
        (params) = abi.decode(crossMessage, (CrossV3SwapParams));
    }

    function fromCrossV2ToSourceV2SwapParams(
        CrossV2SwapParams memory crossParams
    ) internal pure returns(V2SwapParams memory v2SwapParams){
        address[] memory newPath=new address[](crossParams.sourcePath.length);
        unchecked {
            for(uint256 i;i<newPath.length;i++){
                newPath[i]=crossParams.sourcePath[i];
            }
        }
        newPath[newPath.length-1]=address(0);
        v2SwapParams=V2SwapParams({
            index: crossParams.index,
            amountIn: crossParams.amountIn,
            amountOutMin: crossParams.amountOutMin,
            path: newPath,
            to: crossParams.to,
            deadline: crossParams.deadline
        });
    }

    function fromCrossV2ToTargetV2SwapParams(
        CrossV2SwapParams memory crossParams
    ) internal pure returns(V2SwapParams memory v2SwapParams){
        address[] memory newPath=new address[](crossParams.targetPath.length);
        unchecked {
            for(uint256 i;i<newPath.length;i++){
                newPath[i]=crossParams.targetPath[i];
            }
        }
        newPath[0]=address(0);
        v2SwapParams=V2SwapParams({
            index: crossParams.index,
            amountIn: crossParams.amountIn,
            amountOutMin: crossParams.amountOutMin,
            path: newPath,
            to: crossParams.to,
            deadline: crossParams.deadline
        });
    }

    function fromCrossV3ToSourceV3SwapParams(
        CrossV3SwapParams memory crossParams
    ) internal pure returns(V3SwapParams memory v3SwapParams){
        v3SwapParams=V3SwapParams({
            index: crossParams.index,
            fee: crossParams.fee,
            sqrtPriceLimitX96: crossParams.sqrtPriceLimitX96,
            tokenIn: crossParams.sourceChainTokenIn,
            tokenOut: address(0),
            recipient: crossParams.recipient,
            amountIn: crossParams.amountIn,
            amountOutMinimum: crossParams.amountOutMinimum
        });
    }

    function fromCrossV3ToTargetV3SwapParams(
        CrossV3SwapParams memory crossParams
    ) internal pure returns(V3SwapParams memory v3SwapParams){
        v3SwapParams=V3SwapParams({
            index: crossParams.index,
            fee: crossParams.fee,
            sqrtPriceLimitX96: crossParams.sqrtPriceLimitX96,
            tokenIn: address(0),
            tokenOut: crossParams.sourceChainTokenIn,
            recipient: crossParams.recipient,
            amountIn: crossParams.amountIn,
            amountOutMinimum: crossParams.amountOutMinimum
        });
    }

    function encodeCrossETHParams(
        CrossETHParams calldata params
    ) external pure returns (bytes memory crossETHAmount){
        crossETHAmount = abi.encode(params);
    }

    function encodeV2SwapParams(
        V2SwapParams calldata params
    ) external pure returns (bytes memory v2SwapMessageBytes) {
        v2SwapMessageBytes = abi.encode(params);
    }

    function encodeV3SwapParams(
        V3SwapParams calldata params
    ) external pure returns (bytes memory v3SwapMessageBytes) {
        v3SwapMessageBytes = abi.encode(params);
    }

    function encodeCrossV2SwapParams(
        CrossV2SwapParams calldata params
    ) external pure returns (bytes memory crossV2MessageBytes) {
        crossV2MessageBytes = abi.encode(params);
    }

    function encodeCrossV3SwapParams(
        CrossV2SwapParams calldata params
    ) external pure returns (bytes memory crossV3MessageBytes) {
        crossV3MessageBytes = abi.encode(params);
    }

    function toBytes4(bytes memory input) internal pure returns (bytes4 output) {
        require(input.length >= 4, "Input too short");
        assembly {
            output := mload(add(input, 32))
        }
    }
}
