// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/* solhint-disable no-inline-assembly */

import "../../interfaces/zkaa/PackedUserOperation.sol";
import {calldataKeccak, min} from "./Helpers.sol";
import "../utils/Poseidon.sol";

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {
    uint256 public constant PAYMASTER_VALIDATION_GAS_OFFSET = 20;
    uint256 public constant PAYMASTER_POSTOP_GAS_OFFSET = 36;
    uint256 public constant PAYMASTER_DATA_OFFSET = 52;

    uint256 public constant SYSTEM_OPERATION_ACCOUNT_OFFSET = 20;

    uint256 public constant VALIDATE_OWNER_GAS_LIMIT = 10000;

    uint256 public constant USER_OP_BYTES = 32 * 7 + 20;

    uint8 constant NOMAL_OPERATION = 0;
    uint8 constant DEPOSIT_OPERATION = 1;
    uint8 constant WITHDRAW_OPERATION = 2;

    /**
     * Get sender from user operation data.
     * @param userOp - The user operation data.
     */
    function getSender(
        PackedUserOperation calldata userOp
    ) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    /**
     * Relayer/block builder might submit the TX with higher priorityFee,
     * but the user should not pay above what he signed for.
     * @param userOp - The user operation data.
     */
    function gasPrice(
        PackedUserOperation calldata userOp
    ) internal view returns (uint256) {
        return userOp.mainChainGasPrice;
        // unchecked {
        //    return userOp.mainChainGasPrice;
        //     (uint256 maxPriorityFeePerGas, uint256 maxFeePerGas) = unpackUints(
        //         userOp.gasFees
        //     );
        //     if (maxFeePerGas == maxPriorityFeePerGas) {
        //         //legacy mode (for networks that don't support basefee opcode)
        //         return maxFeePerGas;
        //     }
        //     return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        // }
    }

    function getValidateOwnerGasLimit(
        PackedUserOperation calldata userOp
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

    function unpackUints(
        bytes32 packed
    ) internal pure returns (uint256 high128, uint256 low128) {
        return (uint128(bytes16(packed)), uint128(uint256(packed)));
    }

    //unpack just the high 128-bits from a packed value
    function unpackHigh128(bytes32 packed) internal pure returns (uint256) {
        return uint256(packed) >> 128;
    }

    // unpack just the low 128-bits from a packed value
    function unpackLow128(bytes32 packed) internal pure returns (uint256) {
        return uint128(uint256(packed));
    }

    // function unpackMaxPriorityFeePerGas(
    //     PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return unpackHigh128(userOp.gasFees);
    // }

    // function unpackMaxFeePerGas(
    //     PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return unpackLow128(userOp.gasFees);
    // }

    function unpackVerificationGasLimit(
        PackedUserOperation calldata userOp
    ) internal pure returns (uint256) {
        return userOp.zkVerificationGasLimit;
    }

    function unpackCallGasLimit(
        PackedUserOperation calldata userOp
    ) internal pure returns (uint256) {
        return userOp.mainChainGasLimit;
    }

    // function unpackPaymasterVerificationGasLimit(
    //     PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return
    //         uint128(
    //             bytes16(
    //                 userOp
    //                     .paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_POSTOP_GAS_OFFSET]
    //             )
    //         );
    // }

    // function unpackPostOpGasLimit(
    //     PackedUserOperation calldata userOp
    // ) internal pure returns (uint256) {
    //     return
    //         uint128(
    //             bytes16(
    //                 userOp
    //                     .paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET:PAYMASTER_DATA_OFFSET]
    //             )
    //         );
    // }

    function unpackGasOperationData(
        PackedUserOperation calldata userOp
    ) internal pure returns (address, uint256) {
        return (
            address(bytes20(userOp.callData[:SYSTEM_OPERATION_ACCOUNT_OFFSET])),
            uint256(bytes32(userOp.callData[SYSTEM_OPERATION_ACCOUNT_OFFSET:]))
        );
    }

    function isGasOperation(
        PackedUserOperation calldata userOp
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
        PackedUserOperation calldata userOp
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
     * @param userOp - The user operation data.
     */
    function packOpInfo(
        PackedUserOperation calldata userOp
    ) public pure returns (bytes32) {
        return packUints(userOp.nonce, userOp.chainId);
    }

    /**
     * Get pack data for mainChainGasLimit and destChainGasLimit.
     * @param userOp - The user operation data.
     */
    function packChainGasLimit(
        PackedUserOperation calldata userOp
    ) public pure returns (bytes32) {
        return packUints(userOp.mainChainGasLimit, userOp.destChainGasLimit);
    }

    /**
     * Get pack data for mainChainGasPrice and destChainGasPrice.
     * @param userOp - The user operation data.
     */
    function packChainGasPrice(
        PackedUserOperation calldata userOp
    ) public pure returns (bytes32) {
        return packUints(userOp.mainChainGasPrice, userOp.destChainGasPrice);
    }

    // Todo:Poseidon
    /**
     * Pack the user operation data into bytes for hashing.
     * @param userOp - The user operation data.
     */
    function encode(
        PackedUserOperation calldata userOp
    ) internal pure returns (bytes memory) {
        bytes memory encode = new bytes(USER_OP_BYTES);

        bytes32 operation = packOperation(userOp);
        address sender = userOp.sender;
        bytes32 opInfo = packOpInfo(userOp);
        bytes32 calldataHash = calldataKeccak(userOp.callData);
        bytes32 chainGasLimit = packChainGasLimit(userOp);
        uint256 zkVerificationGasLimit = userOp.zkVerificationGasLimit;
        bytes32 chainGasPrice = packChainGasPrice(userOp);
        address owner = userOp.owner;

        assembly {
            mstore(add(encode, 0x20), operation) // 32
            mstore(add(encode, 0x40), sender) // 64
            mstore(add(encode, 0x60), opInfo) // 96
            mstore(add(encode, 0x80), calldataHash) // 128
            mstore(add(encode, 0xa0), chainGasLimit) //160
            mstore(add(encode, 0xc0), zkVerificationGasLimit) // 192
            mstore(add(encode, 0xe0), chainGasPrice) // 224
            mstore(add(encode, 0xf4), owner) // 244
        }

        return encode;
    }
}

library UserOperationsLib {
    function filterByChainId(
        PackedUserOperation[] calldata userOps,
        uint256 chainId
    ) internal pure returns (PackedUserOperation[] memory) {
        uint256 validCount = 0;

        PackedUserOperation[] memory tempArray = new PackedUserOperation[](
            userOps.length
        );

        unchecked {
            for (uint256 i = 0; i < userOps.length; ) {
                if (userOps[i].chainId == chainId) {
                    tempArray[validCount] = userOps[i];
                    ++validCount;
                }
                ++i;
            }
        }

        PackedUserOperation[] memory validArray = new PackedUserOperation[](
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

    function calculateHash(
        PackedUserOperation[] calldata userOps
    ) internal pure returns (bytes32) {
        uint256 userOpBytes = UserOperationLib.USER_OP_BYTES;
        bytes memory encodeBytes = new bytes(userOpBytes * userOps.length);
        unchecked {
            for (uint256 i = 0; i < userOps.length; ) {
                bytes memory encode = UserOperationLib.encode(userOps[i]);

                uint256 offset = i * userOpBytes;

                assembly {
                    let encodePtr := add(encode, 0x20)
                    let encodeBytesPtr := add(add(encodeBytes, 0x20), offset)

                    for {
                        let j := 0
                    } lt(j, userOpBytes) {
                        j := add(j, 0x20)
                    } {
                        mstore(add(encodeBytesPtr, j), mload(add(encodePtr, j)))
                    }
                }

                ++i;
            }
        }

        uint256[4] memory outputs = Poseidon.hashMessage(encodeBytes);
        return Poseidon.mergeUint64ToBytes32(outputs);
    }

    function append(
        PackedUserOperation[] memory target,
        PackedUserOperation[] memory source,
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