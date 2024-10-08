// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

/**
 * Ticket to manage deposit and withdraw.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 */
interface ITicketManager {
    event DepositTicketAdded(
        address indexed user,
        bytes32 indexed ticketHash,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawTicketAdded(
        address indexed user,
        bytes32 indexed ticketHash,
        uint256 amount,
        uint256 timestamp
    );
    event DepositTicketDeleted(
        address indexed user,
        uint256 amount,
        bytes32 ticketHash
    );
    event WithdrawTicketDeleted(
        address indexed user,
        uint256 amount,
        bytes32 ticketHash
    );

    struct Ticket {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    // /**
    //  * @param deposit         - The entity's deposit.
    //  */
    // struct DepositInfo {
    //     uint256 deposit;
    //     // uint256 notConfirmedDeposit;
    // }

    function addDepositTicket(uint256 amount) external payable;

    function addWithdrawTicket(uint256 amount) external;

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
