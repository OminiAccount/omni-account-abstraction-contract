// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

interface BaseStruct {
    struct ExecData {
        uint64 nonce; // only used for batchdata
        uint64 chainId;
        uint64 mainChainGasLimit;
        uint64 destChainGasLimit;
        uint64 zkVerificationGasLimit;
        uint64 mainChainGasPrice;
        uint64 destChainGasPrice;
        bytes callData;
    }
    /**
     * User Operation struct
     * @param sender                - The sender account of this request.
     * @param chainId               - ChainId.
     * @param callData              - The method call to execute on this account.
     * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
     * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
     *                                Covers batch overhead.
     * @param gasFees               - packed gas fields maxPriorityFeePerGas and maxFeePerGas - Same as EIP-1559 gas parameters.
     * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
     *                                The paymaster will pay for the transaction instead of the sender.
     * @param owner                 - Owner of the account that generated this request.
     */
    struct PackedUserOperation {
        uint8 phase; // 0 exec; 1 innerExec
        uint8 operationType; // 0 user; 1 deposit; 2 withdraw;
        uint256 operationValue;
        address sender;
        address owner;
        ExecData exec; // vizing or first chain op
        ExecData innerExec; // empty or second chain op
    }
    /**
     * EntryPoint***********************************************************
     */

    // struct Config {
    //     address entryPoint;
    //     address router;
    // }

    struct BatchData {
        PackedUserOperation[] userOperations; // accInputHash
        bytes32 accInputHash; // Todo: Use the poseidonHash to calculate the value
    }

    struct ChainExecuteExtra {
        uint64 chainId;
        uint64 chainFee;
        uint64 chainUserOperationsNumber;
    }

    struct ChainExecuteInfo {
        ChainExecuteExtra extra;
        PackedUserOperation[] userOperations;
    }

    struct ChainsExecuteInfo {
        ChainExecuteExtra[] chainExtra;
        bytes32 newStateRoot;
        address beneficiary;
    }

    /**
     * A memory copy of UserOp static fields only.
     * Excluding: userAddr, chainId, callData. Replacing paymasterAndData with paymaster.
     */
    struct MemoryUserOp {
        uint8 phase;
        address sender;
        address owner;
        bool innerExec;
        uint256 chainId;
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

    /**
     * SyncRouter***********************************************************
     */

    struct CrossETHParams {
        uint256 amount;
        address reciever;
    }

    /**
     * @notice Use any uniswapV2 router for swap
     * @param index                 - Index router             -
     * @param amountIn     - Input swap token amount
     * @param amountOutMin               - Output token minimum receive amount
     * @param path              - Uniswapv2 tokens swap path
     * @param sender          _touch swap sender
     * @param receiver            - Touch swap output token receiver
     * @param deadline              - Swap deadline
     */
    struct V2SwapParams {
        uint8 index;
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
        address sender;
        address receiver;
        uint256 deadline;
    }

    /**
     * @notice Use any uniswapV3 router for swap
     * @param index                 - Index router
     * @param fee                   - UniswapV3 fee(100==0.01%, 500==0.05%, 3000==0.3%, 10000==1%)
     * @param sqrtPriceLimitX96     - Default input 0
     * @param tokenIn               - Input swap token
     * @param tokenOut              - Output swap token
     * @param sender                - Touch swap sender
     * @param receiver              - Touch swap output token receiver
     * @param amountIn              - Input token amount
     * @param amountOutMinimum      - Output token minimum receive amount
     */
    struct V3SwapParams {
        uint8 index;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenIn;
        address tokenOut;
        address sender;
        address receiver;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct CrossV2SwapParams {
        uint8 sourceIndex;
        uint8 targetIndex;
        uint256 amountIn;
        uint256 amountOutMin;
        address sourceToken;
        address targetToken;
        address sender;
        address receiver;
        uint256 deadline;
    }

    struct CrossV3SwapParams {
        uint8 sourceIndex;
        uint8 targetIndex;
        uint24 sourceFee;
        uint24 targetFee;
        uint160 sourceSqrtPriceLimitX96;
        uint160 targetSqrtPriceLimitX96;
        address sourceChainTokenIn;
        address targetChainTokenOut;
        address sender;
        address receiver;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    //receive message struct
    struct CrossHookMessageParams {
        uint8 way;
        uint24 gasLimit;
        uint64 gasPrice;
        uint64 destChainId;
        uint64 minArrivalTime;
        uint64 maxArrivalTime;
        address destContract;
        address selectedRelayer;
        uint256 destChainExecuteUsedFee; // Amount that the target chain needs to spend to execute userop
        bytes batchsMessage; //bytes PackedUserOperation
        bytes packCrossMessage; //The sending chain sends the instruction to the target chain after encode and executes the call
        bytes packCrossParams;
    }

    //send omni struct
    struct CrossMessageParams {
        PackedUserOperation[] _packedUserOperation;
        CrossHookMessageParams _hookMessageParams;
    }
}