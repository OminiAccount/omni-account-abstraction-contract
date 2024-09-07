// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

import "../interfaces/IStakeManager.sol";

/* solhint-disable avoid-low-level-calls */
/* solhint-disable not-rely-on-time */

/**
 * Manage deposits and stakes.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 * Stake is value locked for at least "unstakeDelay" by a paymaster.
 */
abstract contract StakeManager is IStakeManager {
    /// maps paymaster to their deposits and stakes
    mapping(address => DepositInfo) public deposits;

    /// @inheritdoc IStakeManager
    function getDepositInfo(
        address account
    ) public view returns (DepositInfo memory info) {
        return deposits[account];
    }

    /// @inheritdoc IStakeManager
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account].deposit;
    }

    // receive() external payable {
    //     depositTo(msg.sender);
    // }

    /**
     * Increments an account's deposit.
     * @param account - The account to increment.
     * @param amount  - The amount to increment by.
     * @return the updated deposit of this account
     */
    function _incrementDeposit(
        address account,
        uint256 amount
    ) internal returns (uint256) {
        DepositInfo storage info = deposits[account];
        uint256 newAmount = info.deposit + amount;
        info.deposit = newAmount;
        return newAmount;
    }

    /**
     * Add to the deposit of the given account.
     * @param account - The account to add to.
     */
    function depositTo(address account, uint256 amount) internal {
        uint256 newDeposit = _incrementDeposit(account, amount);
        emit Deposited(account, newDeposit);
    }

    /**
     * Withdraw from the deposit.
     * @param accountAddress  - The address is AA contract address, also is send withdrawn.
     * @param withdrawAmount  - The amount to withdraw.
     */
    function withdrawTo(
        address payable accountAddress,
        uint256 withdrawAmount
    ) internal {
        DepositInfo storage info = deposits[accountAddress];
        require(withdrawAmount <= info.deposit, "Withdraw amount too large");
        info.deposit = info.deposit - withdrawAmount;
        emit Withdrawn(accountAddress, withdrawAmount);
        (bool success, ) = accountAddress.call{value: withdrawAmount}("");
        require(success, "failed to withdraw");
    }
}
