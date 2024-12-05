// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../libraries/Error.sol";
import "../libraries/UserOperationLib.sol";
import "../interfaces/core/IPreGasManager.sol";

contract PreGasManager is IPreGasManager {
    using UserOperationLib for PackedUserOperation;

    mapping(address account => uint256 amount) public preGasBalance;

    /// @inheritdoc IPreGasManager
    function getPreGasBalanceInfo(
        address account
    ) public view returns (uint256) {
        return preGasBalance[account];
    }

    /**
     * Submit a user deposit operation and redeem deposit to SMT
     */
    function submitDepositOperation(
        uint256 amount,
        uint256 nonce
    ) external payable {
        if (msg.value != amount) {
            revert ValueNotEqual();
        }

        preGasBalance[msg.sender] += amount;

        redeemGasOperation(amount, nonce);
    }

    /**
     * Submit a user withdraw operation
     */
    function submitWithdrawOperation(uint256 amount) external {
        emit WithdrawTicketAdded(msg.sender, amount, block.timestamp);
    }

    /**
     * Commit a user deposit operation
     */
    function _commitDepositOperation(
        PackedUserOperation calldata userOp
    ) internal {
        address account = userOp.sender;
        uint256 amount = userOp.operationValue;
        if (preGasBalance[account] < amount) {
            revert InsufficientBalance();
        }
        preGasBalance[account] -= amount;

        emit DepositTicketDeleted(account, amount);
    }

    /**
     * Commit a user withdraw ticket, reduce the deposit of the given account.
     */
    function _commitWithdrawOperation(
        PackedUserOperation calldata userOp
    ) internal {
        address account = userOp.sender;
        uint256 amount = userOp.operationValue;
        if (address(this).balance < amount) {
            revert InsufficientBalance();
        }

        (bool success, ) = payable(account).call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
        emit WithdrawTicketDeleted(account, amount);
    }

    /**
     * Redeem gasBalance to SMT
     */
    function redeemGasOperation(uint256 amount, uint256 nonce) public {
        if (preGasBalance[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        emit DepositTicketAdded(
            keccak256(
                abi.encodePacked(msg.sender, block.chainid, nonce, amount)
            ),
            msg.sender,
            amount,
            block.timestamp
        );
    }
}
