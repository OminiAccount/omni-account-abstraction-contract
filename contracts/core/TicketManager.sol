// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "../interfaces/ITicketManager.sol";

import "./TicketLib.sol";

contract TicketManager is ITicketManager {
    using TicketLib for Ticket;

    error InsufficientBalance();
    error TicketNotExist();
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

        uint256 timestamp = block.timestamp;
        Ticket memory ticket = Ticket(msg.sender, amount, timestamp);
        bytes32 ticketHash = ticket.hash();

        depositTickets[ticketHash] = true;
        emit DepositTicketAdded(msg.sender, ticketHash, amount, timestamp);
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
            revert TicketNotExist();
        }

        depositTickets[ticketHash] = false;

        // uint256 newDeposit = _incrementDeposit(ticket.user, ticket.amount);

        emit DepositTicketDeleted(ticket.user, ticket.amount, 0, ticketHash);
    }

    /**
     * Delete a user withdraw ticket, reduce the deposit of the given account.
     */
    function delWithdrawTicket(Ticket memory ticket) internal {
        bytes32 ticketHash = ticket.hash();
        if (!withdrawTickets[ticketHash]) {
            revert TicketNotExist();
        }

        withdrawTickets[ticketHash] = false;

        // uint256 newDeposit = _reduceDeposit(
        //     payable(ticket.user),
        //     ticket.amount
        // );

        emit WithdrawTicketDeleted(ticket.user, ticket.amount, 0, ticketHash);
    }

    // /// @inheritdoc ITicketManager
    // function getDepositInfo(
    //     address account
    // ) public view returns (DepositInfo memory info) {
    //     return deposits[account];
    // }

    // /// @inheritdoc ITicketManager
    // function balanceOf(address account) public view returns (uint256) {
    //     return deposits[account].deposit;
    // }

    // function _incrementDeposit(
    //     address account,
    //     uint256 amount
    // ) internal returns (uint256) {
    //     DepositInfo storage info = deposits[account];
    //     uint256 newAmount = info.deposit + amount;
    //     info.deposit = newAmount;
    //     return newAmount;
    // }

    // function _reduceDeposit(
    //     address payable account,
    //     uint256 amount
    // ) internal returns (uint256) {
    //     DepositInfo storage info = deposits[account];
    //     if (amount > info.deposit) {
    //         revert InsufficientBalance();
    //     }
    //     info.deposit = info.deposit - amount;
    //     (bool success, ) = account.call{value: amount}("");
    //     if (!success) {
    //         revert CallFailed();
    //     }
    //     return info.deposit;
    // }
}
