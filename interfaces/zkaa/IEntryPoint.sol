/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./PackedUserOperation.sol";
import "./IPreGasManager.sol";

interface IEntryPoint is IPreGasManager {

    struct BatchData {
        PackedUserOperation[] userOperations; // accInputHash
        bytes32 oldStateRoot;
        bytes32 newStateRoot;
        bytes32 accInputHash; // Todo: Use the poseidonHash to calculate the value
    }

    struct ChainExecuteExtra {
        uint256 chainId;
        uint256 chainFee;
        uint256 chainUserOperationsNumber;
    }

    struct ChainExecuteInfo {
        ChainExecuteExtra extra;
        PackedUserOperation[] userOperations;
    }

    struct ChainsExecuteInfo {
        ChainExecuteExtra[] chainExtra;
        address beneficiary;
    }

    function syncBatch(PackedUserOperation[] memory userOps) external;

    /**
     * Execute a batch of UserOperations.
     * No signature aggregator is used.
     * If any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops         - The operations to execute.
     * @param beneficiary - The address to receive the fees.
     * @param isSync      - This flag is used to distinguish verifyBatch or syncBatch()
     */
    function handleOps(
        PackedUserOperation[] calldata ops,
        address payable beneficiary,
        bool isSync
    ) external;

    /**
     * Generate a request Id - unique identifier for this request.
     * The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     * @param userOp - The user operation to generate the request ID for.
     * @return hash the hash of this UserOperation
     */
    function getUserOpHash(
        PackedUserOperation calldata userOp
    ) external view returns (bytes32);

    /**
     * Gas and return values during simulation.
     * @param preOpGas         - The gas used for validation (including preValidationGas)
     * @param prefund          - The required prefund for this operation
     * @param accountValidationData   - returned validationData from account.
     * @param paymasterValidationData - return validationData from paymaster.
     * @param paymasterContext - Returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        uint256 accountValidationData;
        uint256 paymasterValidationData;
        bytes paymasterContext;
    }

    error DelegateAndRevert(bool success, bytes ret);

    /**
     * Helper method for dry-run testing.
     * @dev calling this method, the EntryPoint will make a delegatecall to the given data, and report (via revert) the result.
     *  The method always revert, so is only useful off-chain for dry run calls, in cases where state-override to replace
     *  actual EntryPoint code is less convenient.
     * @param target a target contract to make a delegatecall from entrypoint
     * @param data data to pass to target in a delegatecall
     */
    function delegateAndRevert(address target, bytes calldata data) external;
}
