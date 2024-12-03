// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "../../interfaces/zkaa/IPreGasManager.sol";
import "../../interfaces/IZKVizingAAError.sol";
import "../../interfaces/IZKVizingAAEvent.sol";
import "./UserOperationLib.sol";

contract PreGasManager is IPreGasManager, IZKVizingAAError, IZKVizingAAEvent {
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
    function submitDepositOperation(uint256 amount) external payable {
        if (msg.value != amount) {
            revert ValueNotEqual();
        }

        preGasBalance[msg.sender] += amount;

        redeemGasOperation(amount);
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
    function redeemGasOperation(uint256 amount) public {
        if (preGasBalance[msg.sender] < amount) {
            revert InsufficientBalance();
        }
        emit DepositTicketAdded(msg.sender, amount, block.timestamp);
    }
}
