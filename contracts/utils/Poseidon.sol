// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "../../libraries/GoldilocksPoseidon.sol";

library Poseidon {
    uint256 constant BYTECODE_ELEMENTS_HASH = 8;
    uint256 constant BYTECODE_BYTES_ELEMENT = 7;
    uint256 constant MAX_BYTES_TO_ADD =
        BYTECODE_ELEMENTS_HASH * BYTECODE_BYTES_ELEMENT;

    function hashMessage(
        bytes memory bytecode
    ) public pure returns (uint256[4] memory) {
        // Step 1: Add 0x01
        bytecode = abi.encodePacked(bytecode, bytes1(0x01));

        // Step 2: Padding to a multiple of 56 bytes
        while (bytecode.length % 56 != 0) {
            bytecode = abi.encodePacked(bytecode, bytes1(0x00));
        }

        // Step 3: Set the last byte’s highest bit to 1
        bytecode[bytecode.length - 1] |= 0x80;

        uint256 numHashes = (bytecode.length) / MAX_BYTES_TO_ADD;
        uint256[4] memory tmpHash = [uint256(0), 0, 0, 0];
        uint256 bytesPointer = 0;
        unchecked {
            for (uint256 i = 0; i < numHashes; ) {
                uint256[8] memory elementsToHash;

                // Step 4: Process the next 56-byte chunk
                bytes memory subsetBytecode = sliceBytes(
                    bytecode,
                    bytesPointer,
                    MAX_BYTES_TO_ADD
                );
                bytesPointer += MAX_BYTES_TO_ADD;

                uint56 tmpElem;
                uint256 counter = 0;
                uint256 index = 0;

                for (uint256 j = 0; j < MAX_BYTES_TO_ADD; ) {
                    bytes1 byteToAdd = j < subsetBytecode.length
                        ? subsetBytecode[j]
                        : bytes1(0);
                    tmpElem = (tmpElem >> 8) | (uint56(uint8(byteToAdd)) << 48);
                    counter++;

                    if (counter == BYTECODE_BYTES_ELEMENT) {
                        elementsToHash[index] = uint256(tmpElem);
                        index++;
                        tmpElem = 0;
                        counter = 0;
                    }
                    ++j;
                }

                // Step 5: Poseidon hash the elements, assuming hashNToMNoPad is implemented
                uint256[] memory tmpRoot = GoldilocksPoseidon.hashNToMWithCap(
                    convertFixedToDynamic(
                        [
                            elementsToHash[0],
                            elementsToHash[1],
                            elementsToHash[2],
                            elementsToHash[3],
                            elementsToHash[4],
                            elementsToHash[5],
                            elementsToHash[6],
                            elementsToHash[7]
                        ]
                    ),
                    tmpHash,
                    4
                );

                tmpHash = convertToFixedArray(tmpRoot);
                ++i;
            }
        }

        return tmpHash;
    }

    // Helper: Slices bytes
    function sliceBytes(
        bytes memory data,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(start + length <= data.length, "slice out of bounds");

        bytes memory result = new bytes(length);

        assembly {
            // Calculate the starting position of the data to copy
            let dataPtr := add(data, 0x20) // Skip the length part of the 'data' bytes array
            let resultPtr := add(result, 0x20) // Skip the length part of the 'result' bytes array

            // Move the pointer to the start position
            dataPtr := add(dataPtr, start)

            // Copy the data from 'data' to 'result', 32 bytes at a time
            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 0x20)
            } {
                // Calculate the number of bytes to copy in this iteration
                let chunk := length
                if gt(chunk, 0x20) {
                    chunk := 0x20
                }

                // Copy the chunk from data to result
                mstore(resultPtr, mload(dataPtr))

                // Advance the pointers
                dataPtr := add(dataPtr, 0x20)
                resultPtr := add(resultPtr, 0x20)
            }
        }

        return result;
    }

    // Merges four 64-bit segments into a bytes32 value.
    function mergeUint64ToBytes32(
        uint256[4] memory parts
    ) public pure returns (bytes32) {
        return
            bytes32(
                (parts[3] << 192) |
                    (parts[2] << 128) |
                    (parts[1] << 64) |
                    parts[0]
            );
    }

    function convertToFixedArray(
        uint256[] memory input
    ) private pure returns (uint256[4] memory fixedArray) {
        for (uint256 i = 0; i < 4; i++) {
            if (i < input.length) {
                fixedArray[i] = input[i];
            } else {
                fixedArray[i] = 0;
            }
        }
    }

    function convertFixedToDynamic(
        uint256[8] memory fixedArray
    ) internal pure returns (uint256[] memory) {
        uint256[] memory dynamicArray = new uint256[](8);
        for (uint256 i = 0; i < 8; i++) {
            dynamicArray[i] = fixedArray[i];
        }
        return dynamicArray;
    }
}
