// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

interface ITicketManager {
    event DepositTicketAdded(
        address indexed user,
        uint256 amount,
        bytes32 ticketHash
    );
    event WithdrawTicketAdded(
        address indexed user,
        uint256 amount,
        bytes32 ticketHash
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

    function addDepositTicket(address user, uint256 amount) external payable;

    function addWithdrawTicket(address user, uint256 amount) external;

    function delDepositTicket(Ticket calldata ticket) external;

    function delWithdrawTicket(Ticket calldata ticket) external;
}
