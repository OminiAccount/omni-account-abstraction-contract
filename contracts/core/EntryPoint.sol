// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */

import "../interfaces/IAccount.sol";
import "../interfaces/IAccountExecute.sol";
import "../interfaces/IPaymaster.sol";
import "../interfaces/IEntryPoint.sol";
import "../interfaces/ISyncRouter.sol";
import "../interfaces/IVerifier.sol";

import "../utils/Exec.sol";
import "./SmtManager.sol";
import "./Helpers.sol";
import "./PreGasManager.sol";
import "./ConfigManager.sol";
import "./UserOperationLib.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import "forge-std/console.sol";
/*
 * Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 * Only one instance required on each chain.
 */

/// @custom:security-contact https://bounty.ethereum.org
contract EntryPoint is
    IEntryPoint,
    SmtManager,
    PreGasManager,
    ConfigManager,
    ReentrancyGuard,
    Ownable,
    ERC165
{
    using UserOperationLib for PackedUserOperation;
    using UserOperationsLib for PackedUserOperation[];

    constructor() Ownable(msg.sender) {}

    function _isOwner() internal virtual override onlyOwner {}

    // compensate for innerHandleOps' emit message and deposit refund.
    // allow some slack for future gas price changes.
    uint256 private constant INNER_GAS_OVERHEAD = 10000;

    // Marker for inner call revert on out of gas
    bytes32 private constant INNER_OUT_OF_GAS = hex"deaddead";
    bytes32 private constant INNER_REVERT_LOW_PREFUND = hex"deadaa51";

    uint256 private constant REVERT_REASON_MAX_LEN = 2048;
    uint256 private constant PENALTY_PERCENT = 10;

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        // note: solidity "type(IEntryPoint).interfaceId" is without inherited methods but we want to check everything
        return
            interfaceId ==
            (type(IEntryPoint).interfaceId ^
                type(IPreGasManager).interfaceId) ||
            interfaceId == type(IEntryPoint).interfaceId ||
            interfaceId == type(IPreGasManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * Verify a batch containing userOps and newSmtRoot
     * @param proof The encoded proof.
     * @param batches The encoded public values.
     */
    function verifyBatch(
        bytes calldata proof,
        BatchData[] calldata batches,
        ChainsExecuteInfo calldata chainsExecuteInfos
    ) external payable {
        // First verify proof
        // Todo:Input format needs to be updated
        // IVerifier(verifier).verifyProof(publicValues, proof);

        ChainExecuteInfo[] memory chainExecuteInfos = new ChainExecuteInfo[](
            chainsExecuteInfos.chainExtra.length
        );

        bytes32[] memory batchHashs = new bytes32[](batches.length);

        unchecked {
            for (uint256 i = 0; i < chainsExecuteInfos.chainExtra.length; ) {
                ChainExecuteExtra memory extra = chainsExecuteInfos.chainExtra[
                    i
                ];

                PackedUserOperation[]
                    memory chainUserOps = new PackedUserOperation[](
                        extra.chainUserOperationsNumber
                    );

                uint256 userOpsIndex;

                for (uint256 j = 0; j < batches.length; ) {
                    // batchHashs[j] = batches[j].userOperations.calculateHash();
                    PackedUserOperation[] memory userOps = batches[j]
                        .userOperations
                        .filterByChainId(extra.chainId);

                    chainUserOps.append(userOps, userOpsIndex);

                    userOpsIndex += userOps.length;

                    // update stateRoot
                    // updateSmtRoot(
                    //     batches[j].oldStateRoot,
                    //     batches[j].newStateRoot
                    // );

                    ++j;
                }

                chainExecuteInfos[i].extra = extra;
                chainExecuteInfos[i].userOperations = chainUserOps;

                ++i;
            }
        }

        uint256 startGas = gasleft();
        processBatchs(
            chainExecuteInfos[0].userOperations,
            payable(chainsExecuteInfos.beneficiary),
            false
        );
        uint256 gasUsed = startGas - gasleft();

        bytes memory message = abi.encode(batches, batchHashs);

        // sync stateRoot and destUserOperations to other chain
    }

    function syncBatch(
        PackedUserOperation[] memory userOps
    ) external isSyncRouter {
        // Todo: remove beneficiary address(0x01), because the synchronization module does not need
        processBatchs(userOps, payable(address(0x01)), true);
    }

    function processBatchs(
        PackedUserOperation[] memory userOps,
        address payable beneficiary,
        bool isSync
    ) internal {
        // execute userOps
        // Todo: change handleOps from public to internal, or modify about logic
        // But keep ops is calldata
        this.handleOps(userOps, beneficiary, isSync);
    }

    /**
     * Compensate the caller's beneficiary address with the collected fees of all UserOperations.
     * @param beneficiary - The address to receive the fees.
     * @param amount      - Amount to transfer.
     */
    function _compensate(address payable beneficiary, uint256 amount) internal {
        require(beneficiary != address(0), "AA90 invalid beneficiary");
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "AA91 failed send to beneficiary");
    }

    /**
     * Execute a user operation.
     * @param opIndex    - Index into the opInfo array.
     * @param userOp     - The userOp to execute.
     * @param opInfo     - The opInfo filled by validatePrepayment for this userOp.
     * @return collected - The total amount this userOp paid.
     */
    function _executeUserOp(
        uint256 opIndex,
        PackedUserOperation calldata userOp,
        UserOpInfo memory opInfo
    ) internal returns (uint256 collected) {
        uint256 preGas = gasleft();
        bytes memory context = getMemoryBytesFromOffset(opInfo.contextOffset);
        bool success;
        {
            uint256 saveFreePtr;
            assembly ("memory-safe") {
                saveFreePtr := mload(0x40)
            }
            bytes calldata callData = userOp.callData;
            bytes memory innerCall;
            bytes4 methodSig;
            assembly {
                let len := callData.length
                if gt(len, 3) {
                    methodSig := calldataload(callData.offset)
                }
            }
            if (methodSig == IAccountExecute.executeUserOp.selector) {
                bytes memory executeUserOp = abi.encodeCall(
                    IAccountExecute.executeUserOp,
                    (userOp, opInfo.userOpHash)
                );
                innerCall = abi.encodeCall(
                    this.innerHandleOp,
                    (executeUserOp, opInfo, context)
                );
            } else {
                innerCall = abi.encodeCall(
                    this.innerHandleOp,
                    (callData, opInfo, context)
                );
            }
            assembly ("memory-safe") {
                success := call(
                    gas(),
                    address(),
                    0,
                    add(innerCall, 0x20),
                    mload(innerCall),
                    0,
                    32
                )
                collected := mload(0)
                mstore(0x40, saveFreePtr)
            }
        }
        if (!success) {
            bytes32 innerRevertCode;
            assembly ("memory-safe") {
                let len := returndatasize()
                if eq(32, len) {
                    returndatacopy(0, 0, 32)
                    innerRevertCode := mload(0)
                }
            }
            if (innerRevertCode == INNER_OUT_OF_GAS) {
                // handleOps was called with gas limit too low. abort entire bundle.
                //can only be caused by bundler (leaving not enough gas for inner call)
                revert FailedOp(opIndex, "AA95 out of gas");
            } else if (innerRevertCode == INNER_REVERT_LOW_PREFUND) {
                // innerCall reverted on prefund too low. treat entire prefund as "gas cost"
                uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
                uint256 actualGasCost = opInfo.prefund;
                emitPrefundTooLow(opInfo);
                emitUserOperationEvent(opInfo, false, actualGasCost, actualGas);
                collected = actualGasCost;
            } else {
                emit PostOpRevertReason(
                    opInfo.userOpHash,
                    opInfo.mUserOp.sender,
                    Exec.getReturnData(REVERT_REASON_MAX_LEN)
                );

                uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
                collected = _postExecution(
                    IPaymaster.PostOpMode.postOpReverted,
                    opInfo,
                    context,
                    actualGas
                );
            }
        }
    }

    function emitUserOperationEvent(
        UserOpInfo memory opInfo,
        bool success,
        uint256 actualGasCost,
        uint256 actualGas
    ) internal virtual {
        emit UserOperationEvent(
            opInfo.userOpHash,
            opInfo.mUserOp.sender,
            success,
            actualGasCost,
            actualGas
        );
    }

    function emitPrefundTooLow(UserOpInfo memory opInfo) internal virtual {
        emit UserOperationPrefundTooLow(
            opInfo.userOpHash,
            opInfo.mUserOp.sender
        );
    }

    /**
     * Execute a gas operation.
     * @param gasOp      - The gasOp to execute.
     * @param opInfo     - The opInfo filled by validatePrepayment for this gasOp.
     * @return collected - The total amount this gasOp paid.
     */
    function _processGasOperation(
        PackedUserOperation calldata gasOp,
        UserOpInfo memory opInfo
    ) internal returns (uint256) {
        if (gasOp.operationType == UserOperationLib.DEPOSIT_OPERATION) {
            // 4462 5000
            _commitDepositOperation(gasOp);
        } else if (gasOp.operationType == UserOperationLib.WITHDRAW_OPERATION) {
            // 11462 12000
            _commitWithdrawOperation(gasOp);
        }
        return opInfo.prefund;
    }

    /// @inheritdoc IEntryPoint
    function handleOps(
        PackedUserOperation[] calldata ops,
        address payable beneficiary,
        bool isSync
    ) public nonReentrant {
        uint256 opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

        unchecked {
            for (uint256 i = 0; i < opslen; i++) {
                UserOpInfo memory opInfo = opInfos[i];
                _validatePrepayment(i, ops[i], opInfo);
            }

            uint256 collected = 0;
            emit BeforeExecution();

            for (uint256 i = 0; i < opslen; i++) {
                if (ops[i].isGasOperation()) {
                    collected += _processGasOperation(ops[i], opInfos[i]);
                } else {
                    collected += _executeUserOp(i, ops[i], opInfos[i]);
                }
            }
            if (!isSync) {
                _compensate(beneficiary, collected);
            }
        }
    }

    /**
     * A memory copy of UserOp static fields only.
     * Excluding: userAddr, chainId, callData. Replacing paymasterAndData with paymaster.
     */
    struct MemoryUserOp {
        address sender;
        uint256 chainId;
        uint256 operationValue;
        uint256 zkVerificationGasLimit;
        uint256 mainChainGasLimit;
        uint256 destChainGasLimit;
        uint256 mainChainGasPrice;
        uint256 destChainGasPrice;
    }

    struct UserOpInfo {
        MemoryUserOp mUserOp;
        bytes32 userOpHash;
        uint256 prefund;
        uint256 contextOffset;
        uint256 preOpGas;
    }

    /**
     * Inner function to handle a UserOperation.
     * Must be declared "external" to open a call context, but it can only be called by handleOps.
     * @param callData - The callData to execute.
     * @param opInfo   - The UserOpInfo struct.
     * @param context  - The context bytes.
     * @return actualGasCost - the actual cost in eth this UserOperation paid for gas
     */
    function innerHandleOp(
        bytes memory callData,
        UserOpInfo memory opInfo,
        bytes calldata context
    ) external returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        require(msg.sender == address(this), "AA92 internal call only");
        MemoryUserOp memory mUserOp = opInfo.mUserOp;

        uint256 callGasLimit = mUserOp.mainChainGasLimit * 100;
        // unchecked {
        //     // handleOps was called with gas limit too low. abort entire bundle.
        //     if (
        //         (gasleft() * 63) / 64 <
        //         callGasLimit +
        //             mUserOp.paymasterPostOpGasLimit +
        //             INNER_GAS_OVERHEAD
        //     ) {
        //         assembly ("memory-safe") {
        //             mstore(0, INNER_OUT_OF_GAS)
        //             revert(0, 32)
        //         }
        //     }
        // }

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (callData.length > 0) {
            bool success = Exec.call(mUserOp.sender, 0, callData, callGasLimit);
            if (!success) {
                bytes memory result = Exec.getReturnData(REVERT_REASON_MAX_LEN);
                if (result.length > 0) {
                    emit UserOperationRevertReason(
                        opInfo.userOpHash,
                        mUserOp.sender,
                        result
                    );
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

        unchecked {
            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            return _postExecution(mode, opInfo, context, actualGas);
        }
    }

    /// @inheritdoc IEntryPoint
    function getUserOpHash(
        PackedUserOperation calldata userOp
    ) public view returns (bytes32) {
        return keccak256(userOp.encode());
    }

    /**
     * Copy general fields from userOp into the memory opInfo structure.
     * @param userOp  - The user operation.
     * @param mUserOp - The memory user operation.
     */
    function _copyUserOpToMemory(
        PackedUserOperation calldata userOp,
        MemoryUserOp memory mUserOp
    ) internal pure {
        mUserOp.sender = userOp.sender;
        mUserOp.chainId = userOp.chainId;
        mUserOp.operationValue = userOp.operationValue;
        mUserOp.zkVerificationGasLimit = userOp.zkVerificationGasLimit;
        mUserOp.mainChainGasPrice = userOp.mainChainGasPrice;
        mUserOp.destChainGasPrice = userOp.destChainGasPrice;
        mUserOp.mainChainGasLimit = userOp.mainChainGasLimit;
        mUserOp.destChainGasLimit = userOp.destChainGasLimit;
    }

    /**
     * Get the required prefunded gas fee amount for an operation.
     * @param mUserOp - The user operation in memory.
     */
    function _getRequiredPrefund(
        MemoryUserOp memory mUserOp
    ) internal pure returns (uint256 requiredPrefund) {
        // (mainChainGasLimit + zkVerficationGasLimit) * mainChainGasPrice +
        // destChainGasPrice * destChainGasLimit
        unchecked {
            requiredPrefund =
                (mUserOp.mainChainGasLimit + mUserOp.zkVerificationGasLimit) *
                mUserOp.mainChainGasPrice +
                mUserOp.destChainGasLimit *
                mUserOp.destChainGasPrice;
        }
    }

    /**
     * Validate account and paymaster (if defined) and
     * also make sure total validation doesn't exceed verificationGasLimit.
     * This method is called off-chain (simulateValidation()) and on-chain (from handleOps)
     * @param opIndex - The index of this userOp into the "opInfos" array.
     * @param userOp  - The userOp to validate.
     */
    function _validatePrepayment(
        uint256 opIndex,
        PackedUserOperation calldata userOp,
        UserOpInfo memory outOpInfo
    ) internal {
        uint256 preGas = gasleft();
        MemoryUserOp memory mUserOp = outOpInfo.mUserOp;
        _copyUserOpToMemory(userOp, mUserOp);
        // avoid to over validateOwnerGasLimit
        // outOpInfo.userOpHash = getUserOpHash(userOp);

        // Validate all numeric values in userOp are well below 128 bit, so they can safely be added
        // and multiplied without causing overflow.
        uint256 zkVerificationGasLimit = mUserOp.zkVerificationGasLimit;
        uint256 maxGasValues = mUserOp.mainChainGasLimit |
            mUserOp.zkVerificationGasLimit |
            mUserOp.destChainGasLimit |
            mUserOp.mainChainGasPrice |
            mUserOp.destChainGasPrice;
        require(maxGasValues <= type(uint120).max, "AA94 gas values overflow");
        require(
            mUserOp.operationValue <= type(uint248).max,
            "AA94 operation value overflow"
        );

        uint256 requiredPreFund = _getRequiredPrefund(mUserOp);

        // Check if the account balance is sufficient
        // Constraints are made in the circuit
        // uint256 accountPreBalance = getPreGasBalanceInfo(mUserOp.sender);

        // if (requiredPreFund > accountPreBalance) {
        //     revert FailedOp(opIndex, "AA insufficient account preBalance");
        // }

        uint256 validateOwnerGasLimit = userOp.getValidateOwnerGasLimit();

        bool validationResult = IAccount(mUserOp.sender).validateUserOp{
            gas: validateOwnerGasLimit
        }(userOp.owner);

        if (!validationResult) {
            revert FailedOp(opIndex, "AA owner verification falied");
        }

        // Todo How to check the gas limit of the authentication owner
        unchecked {
            if (preGas - gasleft() > validateOwnerGasLimit) {
                revert FailedOp(opIndex, "AA26 over verificationOwnerGasLimit");
            }
        }

        bytes memory context;

        unchecked {
            outOpInfo.prefund = requiredPreFund;
            outOpInfo.contextOffset = getOffsetOfMemoryBytes(context);
            outOpInfo.preOpGas = preGas - gasleft() + validateOwnerGasLimit;
        }
    }

    /**
     * Process post-operation, called just after the callData is executed.
     * If a paymaster is defined and its validation returned a non-empty context, its postOp is called.
     * The excess amount is refunded to the account (or paymaster - if it was used in the request).
     * @param mode      - Whether is called from innerHandleOp, or outside (postOpReverted).
     * @param opInfo    - UserOp fields and info collected during validation.
     * @param context   - The context returned in validatePaymasterUserOp.
     * @param actualGas - The gas used so far by this user operation.
     */
    function _postExecution(
        IPaymaster.PostOpMode mode,
        UserOpInfo memory opInfo,
        bytes memory context,
        uint256 actualGas
    ) private returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        unchecked {
            address refundAddress;
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            uint256 gasPrice = getUserOpGasPrice(mUserOp);

            refundAddress = mUserOp.sender;
            actualGas += preGas - gasleft();

            // Calculating a penalty for unused execution gas
            {
                uint256 executionGasLimit = mUserOp.zkVerificationGasLimit +
                    mUserOp.mainChainGasLimit +
                    mUserOp.destChainGasLimit;
                uint256 executionGasUsed = actualGas - opInfo.preOpGas;
                // this check is required for the gas used within EntryPoint and not covered by explicit gas limits
                if (executionGasLimit > executionGasUsed) {
                    uint256 unusedGas = executionGasLimit - executionGasUsed;
                    uint256 unusedGasPenalty = (unusedGas * PENALTY_PERCENT) /
                        100;
                    actualGas += unusedGasPenalty;
                }
            }

            actualGasCost = actualGas * gasPrice;

            uint256 prefund = opInfo.prefund;

            // The gas prefund by the user is sufficient to cover the actualGasCost.
            if (prefund < actualGasCost) {
                if (mode == IPaymaster.PostOpMode.postOpReverted) {
                    actualGasCost = prefund;
                    emitPrefundTooLow(opInfo);
                    emitUserOperationEvent(
                        opInfo,
                        false,
                        actualGasCost,
                        actualGas
                    );
                } else {
                    assembly ("memory-safe") {
                        mstore(0, INNER_REVERT_LOW_PREFUND)
                        revert(0, 32)
                    }
                }
            } else {
                bool success = mode == IPaymaster.PostOpMode.opSucceeded;
                emitUserOperationEvent(
                    opInfo,
                    success,
                    actualGasCost,
                    actualGas
                );
            }
        } // unchecked
    }

    /**
     * The gas price this UserOp agrees to pay.
     * Relayer/block builder might submit the TX with higher priorityFee, but the user should not.
     * @param mUserOp - The userOp to get the gas price from.
     */
    function getUserOpGasPrice(
        MemoryUserOp memory mUserOp
    ) internal view returns (uint256) {
        unchecked {
            return
                mUserOp.chainId == block.chainid
                    ? mUserOp.mainChainGasPrice
                    : mUserOp.destChainGasPrice;
        }
    }

    /**
     * The offset of the given bytes in memory.
     * @param data - The bytes to get the offset of.
     */
    function getOffsetOfMemoryBytes(
        bytes memory data
    ) internal pure returns (uint256 offset) {
        assembly {
            offset := data
        }
    }

    /**
     * The bytes in memory at the given offset.
     * @param offset - The offset to get the bytes from.
     */
    function getMemoryBytesFromOffset(
        uint256 offset
    ) internal pure returns (bytes memory data) {
        assembly ("memory-safe") {
            data := offset
        }
    }

    /// @inheritdoc IEntryPoint
    function delegateAndRevert(address target, bytes calldata data) external {
        (bool success, bytes memory ret) = target.delegatecall(data);
        revert DelegateAndRevert(success, ret);
    }
}
