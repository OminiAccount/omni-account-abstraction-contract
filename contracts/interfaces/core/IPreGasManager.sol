// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "../BaseStruct.sol";
/**
 * Ticket to manage deposit and withdraw.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 */

interface IPreGasManager is BaseStruct {
    error ValueNotEqual();
    error CallFailed();

    event DepositTicketAdded(
        bytes32 indexed did,
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawTicketAdded(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event DepositTicketDeleted(address indexed account, uint256 amount);
    event WithdrawTicketDeleted(address indexed account, uint256 amount);

    /**
     * Get preGasBalance info.
     * @param account - The account to query.
     * @return info   - PreGasBalance information of given account.
     */
    function getPreGasBalanceInfo(
        address account
    ) external view returns (uint256);

    // /**
    //  * @param deposit         - The entity's deposit.
    //  */
    // struct DepositInfo {
    //     uint256 deposit;
    //     // uint256 notConfirmedDeposit;
    // }

    function submitDepositOperation(
        uint256 amount,
        uint256 nonce
    ) external payable;

    function submitWithdrawOperation(uint256 amount) external;

    // function redeemGasOperation(uint256 amount, uint256 nonce) external;

    // /**
    //  * Get deposit info.
    //  * @param account - The account to query.
    //  * @return info   - Full deposit information of given account.
    //  */
    // function getDepositInfo(
    //     address account
    // ) external view returns (DepositInfo memory info);

    // /**
    //  * Get account balance.
    //  * @param account - The account to query.
    //  * @return        - The deposit (for gas payment) of the account.
    //  */
    // function balanceOf(address account) external view returns (uint256);
}