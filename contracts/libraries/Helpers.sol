// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable no-inline-assembly */

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
    assembly ("memory-safe") {
        let mem := mload(0x40)
        let len := data.length
        calldatacopy(mem, data.offset, len)
        ret := keccak256(mem, len)
    }
}

/**
 * The minimum of two numbers.
 * @param a - First number.
 * @param b - Second number.
 */
function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}
