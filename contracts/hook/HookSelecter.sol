// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
import {BaseStruct} from "../interfaces/BaseStruct.sol";
abstract contract HookSelecter is BaseStruct{
    function getV2SwapSelector() internal pure returns (bytes4) {
        return bytes4(keccak256("v2Swap((uint8,uint256,uint256,address[],address,uint256))"));
    }

    function getV3SwapSelector() internal pure returns (bytes4) {
        return bytes4(keccak256("v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))"));
    }

    function decodeCrossV2SwapMessage(bytes memory crossMessage)public view returns(V2SwapParams memory params){
        (params)=abi.decode(crossMessage,(V2SwapParams));
    }

    function decodeCrossV3SwapMessage(bytes memory crossMessage)public view returns(V3SwapParams memory params){
        (params)=abi.decode(crossMessage,(V3SwapParams));
    }
    
    function encodeV2SwapParams(
        V2SwapParams calldata params
    ) external pure returns (bytes memory crossMessageBytes) {
        V2SwapParams memory _crossMessage = V2SwapParams({
            index: params.index,
            amountIn: params.amountIn,
            amountOutMin: params.amountOutMin,
            path: params.path,
            to: params.to,
            deadline: params.deadline
        });
        crossMessageBytes = abi.encode(_crossMessage);
    }

    function encodeV3SwapParams(
        V3SwapParams calldata params
    ) external pure returns (bytes memory crossMessageBytes) {
        V3SwapParams memory _crossMessage = V3SwapParams({
            index: params.index,
            fee: params.fee,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            recipient: params.recipient,
            amountIn: params.amountIn,
            amountOutMinimum: params.amountOutMinimum
        });
        crossMessageBytes = abi.encode(_crossMessage);
    }
}