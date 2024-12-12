// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

error InsufficientBalance();

error InvalidData();

error CallFailed();

error ValueNotEqual();

error InvalidPath();

error InvalidWay();

error ExecutionCompleted();

/**
 * A custom revert error of handleOps, to identify the offending op.
 * Should be caught in off-chain handleOps simulation and not happen on-chain.
 * Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
 * NOTE: If simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
 * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
 * @param reason  - Revert reason. The string starts with a unique code "AAmn",
 *                  where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
 *                  so a failure can be attributed to the correct entity.
 */
error FailedOp(uint256 opIndex, string reason);

/**
 * A custom revert error of handleOps, to report a revert by account or paymaster.
 * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
 * @param reason  - Revert reason. see FailedOp(uint256,string), above
 * @param inner   - data from inner cought revert reason
 * @dev note that inner is truncated to 2048 bytes
 */
error FailedOpWithRevert(uint256 opIndex, string reason, bytes inner);

error PostOpReverted(bytes returnData);

// Return value of getSenderAddress.
error SenderAddressResult(address sender);