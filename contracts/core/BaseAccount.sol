// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-empty-blocks */

import "../interfaces/core/IAccount.sol";
import "../interfaces/core/IEntryPoint.sol";
import "../libraries/UserOperationLib.sol";

/**
 * Basic account implementation.
 * This contract provides the basic logic for implementing the IAccount interface - validateUserOp
 * Specific account implementation should inherit it and provide the account-specific logic.
 */
abstract contract BaseAccount is IAccount {
    using UserOperationLib for PackedUserOperation;

    /**
     * Return the entryPoint used by this account.
     * Subclass should return the current entryPoint used by this account.
     */
    function entryPoint() public view virtual returns (IEntryPoint);

    /// @inheritdoc IAccount
    function validateUserOp(
        address _owner
    ) external virtual override returns (bool) {
        _requireFromEntryPoint();
        return _validateOwner(_owner);
    }

    /**
     * Ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal view virtual {
        require(
            msg.sender == address(entryPoint()),
            "account: not from EntryPoint"
        );
    }

    /**
     * Validate the _owner is valid for IAccount owner.
     * @param _owner            - Owner of the account that generated this request.
     * @return validationResult - Address verification result.
     */
    function _validateOwner(
        address _owner
    ) internal virtual returns (bool validationResult);
}
