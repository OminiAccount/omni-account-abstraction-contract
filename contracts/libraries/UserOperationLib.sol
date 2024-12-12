// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/* solhint-disable no-inline-assembly */

import {calldataKeccak, min} from "./Helpers.sol";
import "../utils/Poseidon.sol";
import "../interfaces/BaseStruct.sol";

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {
    uint256 public constant PAYMASTER_VALIDATION_GAS_OFFSET = 20;
    uint256 public constant PAYMASTER_POSTOP_GAS_OFFSET = 36;
    uint256 public constant PAYMASTER_DATA_OFFSET = 52;

    uint256 public constant SYSTEM_OPERATION_ACCOUNT_OFFSET = 20;

    uint256 public constant VALIDATE_OWNER_GAS_LIMIT = 10_000;

    uint256 public constant USER_OP_BYTES = 32 * 7 + 20;

    uint8 constant NOMAL_OPERATION = 0;
    uint8 constant DEPOSIT_OPERATION = 1;
    uint8 constant WITHDRAW_OPERATION = 2;

    function getExec(
        BaseStruct.PackedUserOperation calldata userOp
    ) internal pure returns (BaseStruct.ExecData memory) {
        return userOp.phase == 0 ? userOp.exec : userOp.innerExec;
    }

    // /**
    //  * Get sender from user operation data.
    //  * @param userOp - The user operation data.
    //  */
    // function getSender(
    //     BaseStruct.PackedUserOperation calldata userOp
    // ) internal pure returns (address) {
    //     address data;
    //     //read sender from userOp, which is first userOp member (saves 800 gas...)
    //     assembly {
    //         data := calldataload(userOp)
    //     }
    //     return address(uint160(data));
    // }

    // function getCalldata(
    //     BaseStruct.PackedUserOperation calldata userOp
    // ) internal pure returns (BaseStruct.ExecCalldata memory execCalldata) {
    //     if (userOp.chainId.length == 2) {
    //         (
    //             BaseStruct.ExecCalldata memory execCalldata0,
    //             BaseStruct.ExecCalldata memory execCalldata1
    //         ) = abi.decode(
    //                 userOp.callData,
    //                 (BaseStruct.ExecCalldata, BaseStruct.ExecCalldata)
    //             );
    //         if (userOp.index == 0) {
    //             execCalldata = execCalldata0;
    //         } else if (userOp.index == 1) {
    //             execCalldata = execCalldata1;
    //         }
    //     } else if (userOp.chainId.length == 1) {
    //         (execCalldata) = abi.decode(
    //             userOp.callData,
    //             (BaseStruct.ExecCalldata)
    //         );
    //     }
    // }

    // /**
    //  * Relayer/block builder might submit the TX with higher priorityFee,
    //  * but the user should not pay above what he signed for.
    //  * @param userOp - The user operation data.
    //  */
    // function gasPrice(
    //     BaseStruct.PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return userOp.mainChainGasPrice;
    //     // unchecked {
    //     //    return userOp.mainChainGasPrice;
    //     //     (uint256 maxPriorityFeePerGas, uint256 maxFeePerGas) = unpackUints(
    //     //         userOp.gasFees
    //     //     );
    //     //     if (maxFeePerGas == maxPriorityFeePerGas) {
    //     //         //legacy mode (for networks that don't support basefee opcode)
    //     //         return maxFeePerGas;
    //     //     }
    //     //     return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    //     // }
    // }

    function getValidateOwnerGasLimit(
        BaseStruct.PackedUserOperation calldata userOp
    ) internal pure returns (uint256) {
        return VALIDATE_OWNER_GAS_LIMIT;
    }

    function packUints(
        uint256 high128,
        uint256 low128
    ) public pure returns (bytes32 packed) {
        require(high128 <= type(uint128).max, "high128 exceeds uint128 range");
        require(low128 <= type(uint128).max, "low128 exceeds uint128 range");
        packed = bytes32((high128 << 128) | low128);
    }

    function packUint64s(
        uint64 high64,
        uint64 low64
    ) public pure returns (bytes16 packed) {
        packed = bytes16((uint128(high64) << 64) | uint128(low64));
    }

    // function unpackUints(
    //     bytes32 packed
    // ) internal pure returns (uint256 high128, uint256 low128) {
    //     return (uint128(bytes16(packed)), uint128(uint256(packed)));
    // }

    // //unpack just the high 128-bits from a packed value
    // function unpackHigh128(bytes32 packed) internal pure returns (uint256) {
    //     return uint256(packed) >> 128;
    // }

    // // unpack just the low 128-bits from a packed value
    // function unpackLow128(bytes32 packed) internal pure returns (uint256) {
    //     return uint128(uint256(packed));
    // }

    // // function unpackMaxPriorityFeePerGas(
    // //     PackedUserOperation calldata userOp
    // // ) internal pure returns (uint256) {
    // //     return unpackHigh128(userOp.gasFees);
    // // }

    // // function unpackMaxFeePerGas(
    // //     PackedUserOperation calldata userOp
    // // ) internal pure returns (uint256) {
    // //     return unpackLow128(userOp.gasFees);
    // // }

    // function unpackVerificationGasLimit(
    //     BaseStruct.PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return userOp.zkVerificationGasLimit;
    // }

    // function unpackCallGasLimit(
    //     BaseStruct.PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return userOp.mainChainGasLimit;
    // }

    // // function unpackPaymasterVerificationGasLimit(
    // //     PackedUserOperation calldata userOp
    // // ) internal pure returns (uint256) {
    // //     return
    // //         uint128(
    // //             bytes16(
    // //                 userOp
    // //                     .paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_POSTOP_GAS_OFFSET]
    // //             )
    // //         );
    // // }

    // // function unpackPostOpGasLimit(
    // //     PackedUserOperation calldata userOp
    // // ) internal pure returns (uint256) {
    // //     return
    // //         uint128(
    // //             bytes16(
    // //                 userOp
    // //                     .paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET:PAYMASTER_DATA_OFFSET]
    // //             )
    // //         );
    // // }

    function isGasOperation(
        BaseStruct.PackedUserOperation calldata userOp
    ) internal pure returns (bool) {
        return
            userOp.operationType == DEPOSIT_OPERATION ||
            userOp.operationType == WITHDRAW_OPERATION;
    }

    // Helper for calculate

    /**
     * Get pack data for operationType and operationValue.
     * @param userOp - The user operation data.
     */
    function packOperation(
        BaseStruct.PackedUserOperation calldata userOp
    ) public pure returns (bytes32 encoded) {
        uint8 operationType = userOp.operationType;
        uint248 operationValue = uint248(userOp.operationValue);

        assembly {
            // Put the operationType into the first byte of the encoded (the most significant byte)
            encoded := shl(248, operationType)

            // Add operationValue to the lower 31 bytes of the encoded
            encoded := or(encoded, operationValue)
        }
    }

    /**
     * Get pack data for nonce and chainId.
     * @param exec - The exec data.
     */
    function packOpInfo(
        BaseStruct.ExecData calldata exec
    ) public pure returns (bytes32) {
        return packUints(exec.nonce, exec.chainId);
    }

    /**
     * Get pack data for mainChainGasLimit and destChainGasLimit.
     * @param exec - The exec data.
     */
    function packChainGasLimit(
        BaseStruct.ExecData calldata exec
    ) public pure returns (bytes32) {
        return packUints(exec.mainChainGasLimit, exec.destChainGasLimit);
    }

    /**
     * Get pack data for mainChainGasPrice and destChainGasPrice.
     * @param exec - The exec data.
     */
    function packChainGasPrice(
        BaseStruct.ExecData calldata exec
    ) public pure returns (bytes32) {
        return packUints(exec.mainChainGasPrice, exec.destChainGasPrice);
    }

    function encodeExecData(
        BaseStruct.ExecData calldata exec
    ) internal pure returns (bytes memory) {
        bytes memory encodeBytes;
        //is not empty
        if (exec.chainId != 0) {
            // encodeBytes = new bytes(USER_OP_BYTES);
            bytes32 opInfo = packOpInfo(exec);
            bytes32 calldataHash = calldataKeccak(exec.callData);
            bytes32 chainGasLimit = packChainGasLimit(exec);
            uint256 zkVerificationGasLimit = exec.zkVerificationGasLimit;
            bytes32 chainGasPrice = packChainGasPrice(exec);
            encodeBytes = abi.encode(
                opInfo,
                calldataHash,
                chainGasLimit,
                zkVerificationGasLimit,
                chainGasPrice
            );
        }

        return encodeBytes;
    }

    // Todo:Poseidon
    /**
     * Pack the user operation data into bytes for hashing.
     * @param userOp - The user operation data.
     */
    function encode(
        BaseStruct.PackedUserOperation calldata userOp
    ) internal pure returns (bytes memory) {
        // bytes memory encodeBytes = new bytes(USER_OP_BYTES);

        bytes32 operation = packOperation(userOp);
        address sender = userOp.sender;
        address owner = userOp.owner;
        bytes memory encodeBytes = abi.encode(
            operation,
            sender,
            owner,
            encodeExecData(userOp.exec),
            encodeExecData(userOp.innerExec)
        );

        // assembly {
        //     mstore(add(encodeBytes, 0x20), operation) // 32
        //     mstore(add(encodeBytes, 0x40), sender) // 64
        //     mstore(add(encodeBytes, 0x60), opInfo) // 96
        //     mstore(add(encodeBytes, 0x80), calldataHash) // 128
        //     mstore(add(encodeBytes, 0xa0), chainGasLimit) //160
        //     mstore(add(encodeBytes, 0xc0), zkVerificationGasLimit) // 192
        //     mstore(add(encodeBytes, 0xe0), chainGasPrice) // 224
        //     mstore(add(encodeBytes, 0xf4), owner) // 244
        // }

        return encodeBytes;
    }
}

library UserOperationsLib {
    function filterByChainId(
        BaseStruct.PackedUserOperation[] calldata userOps,
        uint256 chainId
    ) internal pure returns (BaseStruct.PackedUserOperation[] memory) {
        uint256 validCount = 0;

        BaseStruct.PackedUserOperation[]
            memory tempArray = new BaseStruct.PackedUserOperation[](
                userOps.length
            );

        unchecked {
            for (uint256 i = 0; i < userOps.length; ) {
                BaseStruct.ExecData memory execData = UserOperationLib.getExec(
                    userOps[i]
                );
                if (execData.chainId == chainId) {
                    tempArray[validCount] = userOps[i];
                    ++validCount;
                }
                ++i;
            }
        }

        BaseStruct.PackedUserOperation[]
            memory validArray = new BaseStruct.PackedUserOperation[](
                validCount
            );

        unchecked {
            for (uint256 j = 0; j < validCount; ) {
                validArray[j] = tempArray[j];
                ++j;
            }
        }

        return validArray;
    }

    // function calculateHash(
    //     BaseStruct.PackedUserOperation[] calldata userOps
    // ) internal pure returns (bytes32) {
    //     uint256 userOpBytes = UserOperationLib.USER_OP_BYTES;
    //     bytes memory encodeBytes = new bytes(userOpBytes * userOps.length);
    //     unchecked {
    //         for (uint256 i = 0; i < userOps.length; ) {
    //             bytes memory encode = UserOperationLib.encode(userOps[i]);

    //             uint256 offset = i * userOpBytes;

    //             assembly {
    //                 let encodePtr := add(encode, 0x20)
    //                 let encodeBytesPtr := add(add(encodeBytes, 0x20), offset)

    //                 for {
    //                     let j := 0
    //                 } lt(j, userOpBytes) {
    //                     j := add(j, 0x20)
    //                 } {
    //                     mstore(add(encodeBytesPtr, j), mload(add(encodePtr, j)))
    //                 }
    //             }

    //             ++i;
    //         }
    //     }

    //     uint256[4] memory outputs = Poseidon.hashMessage(encodeBytes);
    //     return Poseidon.mergeUint64ToBytes32(outputs);
    // }

    function append(
        BaseStruct.PackedUserOperation[] memory target,
        BaseStruct.PackedUserOperation[] memory source,
        uint256 startIndex
    ) internal pure {
        require(
            target.length >= startIndex + source.length,
            "Target array too small"
        );

        for (uint256 i = 0; i < source.length; i++) {
            target[startIndex + i] = source[i];
        }
    }
}