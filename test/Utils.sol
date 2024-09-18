// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import "forge-std/Test.sol";
import "contracts/SimpleAccount.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/SimpleAccountFactory.sol";

contract Utils is Test {
    function encodeTransferCalldata(
        address to,
        uint256 amount
    ) public pure returns (bytes memory data) {
        return
            abi.encodeWithSelector(
                SimpleAccount.execute.selector,
                to,
                amount,
                ""
            );
    }

    function packUints(
        uint256 high128,
        uint256 low128
    ) public pure returns (bytes32 packed) {
        require(high128 < 2 ** 128, "high128 exceeds 128 bits");
        require(low128 < 2 ** 128, "low128 exceeds 128 bits");

        // Combine high128 and low128 into a single bytes32 value
        packed = bytes32((high128 << 128) | low128);
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function getAccountInitCode(
        address owner,
        address factory,
        uint256 salt
    ) public pure returns (bytes memory) {
        bytes4 selector = SimpleAccountFactory.createAccount.selector;

        bytes memory encodedData = abi.encodeWithSelector(
            selector,
            owner,
            salt
        );

        return abi.encodePacked(factory, encodedData);
    }

    function deposit(
        address _owner,
        address payable account,
        uint256 _depositValue
    ) public returns (ITicketManager.Ticket[] memory) {
        ITicketManager.Ticket[]
            memory depositTickets = new ITicketManager.Ticket[](1);
        vm.recordLogs();
        vm.startPrank(_owner);
        SimpleAccount(account).addDeposit{value: _depositValue}();
        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        (uint256 amount, uint256 timestamp) = abi.decode(
            entries[0].data,
            (uint256, uint256)
        );

        ITicketManager.Ticket memory ticket = ITicketManager.Ticket(
            account,
            amount,
            timestamp
        );
        depositTickets[0] = ticket;
        return depositTickets;
    }
}
