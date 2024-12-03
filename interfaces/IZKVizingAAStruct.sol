// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IZKVizingAAStruct{
    /************************************************EntryPoint*********************************************************** */

    /**
     * A memory copy of UserOp static fields only.
     * Excluding: userAddr, chainId, callData. Replacing paymasterAndData with paymaster.
     */
    struct MemoryUserOp {
        address sender;
        uint256 chainId;
        uint256 operationValue;
        uint64 zkVerificationGasLimit;
        uint64 mainChainGasLimit;
        uint64 destChainGasLimit;
        uint128 mainChainGasPrice;
        uint128 destChainGasPrice;
    }
    

    struct UserOpInfo {
        MemoryUserOp mUserOp;
        bytes32 userOpHash;
        uint256 prefund;
        uint256 contextOffset;
        uint256 preOpGas;
    }


    /************************************************SyncRouter*********************************************************** */
    
    /**
     * @notice Use any uniswapV3 router for swap
     * @param index                 - Index router
     * @param fee                   - UniswapV3 fee(100==0.01%, 500==0.05%, 3000==0.3%, 10000==1%)
     * @param sqrtPriceLimitX96     - Default input 0
     * @param tokenIn               - Input swap token
     * @param tokenOut              - Output swap token
     * @param recipient             - Touch swap output token receiver
     * @param amountIn              - Input token amount
     * @param amountOutMinimum      - Output token minimum receive amount
     */
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
    
    /**
     * @notice Use any uniswapV2 router for swap
     * @param index                 - Index router             - 
     * @param amountIn     - Input swap token amount
     * @param amountOutMin               - Output token minimum receive amount
     * @param path              - Uniswapv2 tokens swap path
     * @param to             - Touch swap output token receiver
     * @param deadline              - Swap deadline
     */
    struct V2SwapParams{
        uint8 index;
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