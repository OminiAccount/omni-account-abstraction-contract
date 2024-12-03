// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

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
    uint8 operationType; // 0 user; 1 deposit,2 withdraw system
    uint256 operationValue;
    address sender;
    uint64 nonce; // only used for batchdata
    uint64 chainId;
    bytes callData;
    uint64 mainChainGasLimit;
    uint64 destChainGasLimit;
    uint64 zkVerificationGasLimit;
    uint128 mainChainGasPrice;
    uint128 destChainGasPrice;
    address owner;
}
