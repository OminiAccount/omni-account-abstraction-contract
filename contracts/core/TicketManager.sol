// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../interfaces/ITicketManager.sol";

import "./TicketLib.sol";

contract TicketManager is ITicketManager {
    using TicketLib for Ticket;

    mapping(bytes32 => bool) public depositTickets;
    mapping(bytes32 => bool) public withdrawTickets;

    /**
     * Add a user deposit ticket
     */
    function addDepositTicket(address user, uint256 amount) external payable {
        require(msg.value == amount, "VNE");
        require(user != address(0), "USER0");

        Ticket memory ticket = Ticket(user, amount, block.timestamp);
        bytes32 ticketHash = ticket.hash();

        depositTickets[ticketHash] = true;

        emit DepositTicketAdded(user, amount, ticketHash);
    }

    /**
     * Add a user withdraw ticket
     */
    function addWithdrawTicket(address user, uint256 amount) external {
        require(user != address(0), "USER0");

        Ticket memory ticket = Ticket(user, amount, block.timestamp);
        bytes32 ticketHash = ticket.hash();

        withdrawTickets[ticketHash] = true;

        emit WithdrawTicketAdded(user, amount, ticketHash);
    }

    /**
     * Delete a user deposit ticket
     */
    function delDepositTicket(Ticket memory ticket) internal {
        bytes32 ticketHash = ticket.hash();
        require(depositTickets[ticketHash], "THNE1");

        depositTickets[ticketHash] = false;

        emit DepositTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }

    /**
     * Delete a user withdraw ticket
     */
    function delWithdrawTicket(Ticket memory ticket) internal {
        bytes32 ticketHash = ticket.hash();
        require(withdrawTickets[ticketHash], "THNE2");

        withdrawTickets[ticketHash] = false;

        emit WithdrawTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }
}
