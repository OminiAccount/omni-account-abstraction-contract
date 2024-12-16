// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "../libraries/Error.sol";
import "../libraries/UserOperationLib.sol";
import "../interfaces/core/IPreGasManager.sol";

contract PreGasManager is IPreGasManager {
    using UserOperationLib for PackedUserOperation;

    mapping(address account => uint256 amount) private preGasBalance;

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
        // if (msg.value != amount) {
        //     revert ValueNotEqual();
        // }
        require(msg.value == amount);

        preGasBalance[msg.sender] += amount;

        redeemGasOperation(msg.sender, amount, nonce);
    }

    function _submitDepositOperationRemote(
        address sender,
        uint256 amount,
        uint256 nonce
    ) internal {
        // if (msg.value != amount) {
        //     revert ValueNotEqual();
        // }
        require(msg.value == amount);

        preGasBalance[sender] += amount;

        redeemGasOperation(sender, amount, nonce);
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
        // if (preGasBalance[account] < amount) {
        //     revert InsufficientBalance();
        // }
        require(preGasBalance[account] >= amount);
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
        // if (address(this).balance < amount) {
        //     revert InsufficientBalance();
        // }
        require(address(this).balance >= amount);

        (bool success, ) = payable(account).call{value: amount}("");
        // if (!success) {
        //     revert CallFailed();
        // }
        require(success);
        emit WithdrawTicketDeleted(account, amount);
    }

    /**
     * Redeem gasBalance to SMT
     */
    function redeemGasOperation(
        address sender,
        uint256 amount,
        uint256 nonce
    ) internal {
        // if (preGasBalance[sender] < amount) {
        //     revert InsufficientBalance();
        // }
       require(preGasBalance[sender] >= amount);
        emit DepositTicketAdded(
            keccak256(abi.encodePacked(sender, block.chainid, nonce, amount)),
            sender,
            amount,
            block.timestamp
        );
    }
}