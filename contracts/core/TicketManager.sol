// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../interfaces/ITicketManager.sol";

import "./TicketLib.sol";

contract TicketManager is ITicketManager {
    using TicketLib for Ticket;
    address public entrypoint;
    mapping(bytes32 => bool) public depositTickets;
    mapping(bytes32 => bool) public withdrawTickets;

    modifier onlyEntryPoint() {
        require(msg.sender == entrypoint, "NOTEP");
        _;
    }

    constructor(address _entryPoint) {
        require(_entryPoint != address(0), "EP0");
        entrypoint = _entryPoint;
    }

    /**
     * deposit more funds for this account in the TicketManager
     */
    function addDepositTicket(address user, uint256 amount) external payable {
        require(msg.value == amount, "VNE");
        require(user != address(0), "USER0");

        Ticket memory ticket = Ticket(user, amount, block.timestamp);
        bytes32 ticketHash = ticket.hash();

        depositTickets[ticketHash] = true;

        emit DepositTicketAdded(user, amount, ticketHash);
    }

    function addWithdrawTicket(address user, uint256 amount) external {
        require(user != address(0), "USER0");

        Ticket memory ticket = Ticket(user, amount, block.timestamp);
        bytes32 ticketHash = ticket.hash();

        withdrawTickets[ticketHash] = true;

        emit WithdrawTicketAdded(user, amount, ticketHash);
    }

    function delDepositTicket(Ticket calldata ticket) external onlyEntryPoint {
        bytes32 ticketHash = ticket.hash();
        require(depositTickets[ticketHash], "THNE1");

        depositTickets[ticketHash] = false;

        payable(msg.sender).transfer(ticket.amount);

        emit DepositTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }

    function delWithdrawTicket(Ticket calldata ticket) external onlyEntryPoint {
        bytes32 ticketHash = ticket.hash();
        require(withdrawTickets[ticketHash], "THNE2");

        withdrawTickets[ticketHash] = false;

        emit WithdrawTicketDeleted(ticket.user, ticket.amount, ticketHash);
    }
}
