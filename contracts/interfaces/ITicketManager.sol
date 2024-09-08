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
        uint256 totalDeposit,
        bytes32 ticketHash
    );
    event WithdrawTicketDeleted(
        address indexed user,
        uint256 amount,
        uint256 totalDeposit,
        bytes32 ticketHash
    );

    // event Deposited(address indexed account, uint256 totalDeposit);

    // event Withdrawn(address indexed account, uint256 amount);

    struct Ticket {
        address user;
        uint256 amount;
        uint256 timestamp;
    }

    /**
     * @param deposit         - The entity's deposit.
     * @param staked          - True if this entity is staked.
     * @param stake           - Actual amount of ether staked for this entity.
     * @param unstakeDelaySec - Minimum delay to withdraw the stake.
     * @param withdrawTime    - First block timestamp where 'withdrawStake' will be callable, or zero if already locked.
     * @dev Sizes were chosen so that deposit fits into one cell (used during handleOp)
     *      and the rest fit into a 2nd cell (used during stake/unstake)
     *      - 112 bit allows for 10^15 eth
     *      - 48 bit for full timestamp
     *      - 32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint256 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    function addDepositTicket(uint256 amount) external payable;

    function addWithdrawTicket(uint256 amount) external;

    /**
     * Get deposit info.
     * @param account - The account to query.
     * @return info   - Full deposit information of given account.
     */
    function getDepositInfo(
        address account
    ) external view returns (DepositInfo memory info);

    /**
     * Get account balance.
     * @param account - The account to query.
     * @return        - The deposit (for gas payment) of the account.
     */
    function balanceOf(address account) external view returns (uint256);
}
