//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface IVizingSwap {
    ///struct
    struct V3SwapParams {
        uint8 index;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    
    struct V2SwapParams{
        uint8 index;
        uint8 v2SwapWay;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        address to;
        uint256 deadline;
    }

    
    struct CrossParams {
        uint8 way;
        uint24 gasLimit;
        uint64 gasPrice;
        uint64 destChainId;
        uint64 minArrivalTime;
        uint64 maxArrivalTime;
        address destContract;
        address selectedRelayer;
        uint256 destChainUsedFee; // Amount that the target chain needs to spend to execute userop
        bytes batchsMessage;
        bytes packCrossMessage;
    }


}
