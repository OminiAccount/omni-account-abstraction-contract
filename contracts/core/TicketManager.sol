// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../interfaces/ITicketManager.sol";

import "./TicketLib.sol";

contract TicketManager is ITicketManager {
    using TicketLib for Ticket;

    error InsufficientBalance();
    error TicketNotExist(Ticket ticket);
    error ValueNotEqual();
    error CallFailed();

    /// maps paymaster to their deposits
    // mapping(address => DepositInfo) public deposits;

    mapping(bytes32 => bool) public depositTickets;
    mapping(bytes32 => bool) public withdrawTickets;

    /**
     * Add a user deposit ticket
     */
    function addDepositTicket(uint256 amount) external payable {
        if (msg.value != amount) {
            revert ValueNotEqual();
        }

        Ticket memory ticket = Ticket(msg.sender, amount, block.timestamp);
        bytes32 ticketHash = ticket.hash();

        depositTickets[ticketHash] = true;
        emit DepositTicketAdded(
            msg.sender,
            ticketHash,
            amount,
            block.timestamp
        );
    }

    /**
     * Add a user withdraw ticket
     */
    function addWithdrawTicket(uint256 amount) external {
        uint256 timestamp = block.timestamp;
        Ticket memory ticket = Ticket(msg.sender, amount, timestamp);
        bytes32 ticketHash = ticket.hash();

        withdrawTickets[ticketHash] = true;

        emit WithdrawTicketAdded(msg.sender, ticketHash, amount, timestamp);
    }

    /**
     * Delete a user deposit ticket, add to the deposit of the given account.
     */
    function delDepositTicket(Ticket memory ticket) internal {
        bytes32 ticketHash = ticket.hash();
        if (!depositTickets[ticketHash]) {
            revert TicketNotExist(ticket);
        }

        depositTickets[ticketHash] = false;

        emit DepositTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }

    /**
     * Delete a user withdraw ticket, reduce the deposit of the given account.
     */
    function delWithdrawTicket(Ticket memory ticket) internal {
        bytes32 ticketHash = ticket.hash();
        if (!withdrawTickets[ticketHash]) {
            revert TicketNotExist(ticket);
        }

        withdrawTickets[ticketHash] = false;

        emit WithdrawTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }
}
