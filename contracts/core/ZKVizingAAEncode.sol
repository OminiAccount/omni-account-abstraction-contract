// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;
import {IZKVizingAAStruct} from "../../interfaces/IZKVizingAAStruct.sol";

contract ZKVizingAAEncode is IZKVizingAAStruct{
    
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