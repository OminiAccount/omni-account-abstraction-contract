// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable no-inline-assembly */
import "../interfaces/ITicketManager.sol";

/**
 * Utility functions helpful when working with Ticket structs.
 */
library TicketLib {
    /**
     * Hash the ticket data.
     * @param ticket - The ticket data.
     */
    function hash(
        ITicketManager.Ticket memory ticket
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ticket.user, ticket.amount, ticket.timestamp)
            );
    }
}
