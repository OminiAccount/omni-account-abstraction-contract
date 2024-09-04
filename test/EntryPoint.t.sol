// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/ITicketManager.sol";
import "contracts/SimpleAccount.sol";
import "contracts/SimpleAccountFactory.sol";

contract EntryPointTest is Test {
    EntryPoint ep;
    SimpleAccountFactory factory;

    address account1Owner = address(0x01);
    address account2Owner = address(0x02);
    SimpleAccount account1;
    function setUp() public {
        ep = new EntryPoint();
        factory = new SimpleAccountFactory(ep);
        account1 = factory.createAccount(account1Owner, 0);
        vm.deal(account1Owner, 20 ether);

        console.log("ep address", address(ep));
        console.log("factory address", address(factory));
    }

    function test_deposit_withdraw() public {
        account1OwnerDeposit();
        console.log();
        account1OwnerWithdraw();
    }

    function test_account_execute() public {
        account1OwnerDeposit();
        console.log();
        account1OwnerExecuteTransfer();
    }

    function test_ep_execute() public {
        account1OwnerDeposit();
        console.log();
    }

    function account1OwnerDeposit() public {
        console.log("=== account1Owner will deposit to ep ===");
        vm.startPrank(account1Owner);
        console.log("account1 deposit balance before", account1Owner.balance);
        console.log("ep balance before", address(ep).balance);
        account1.addDeposit{value: 10 ether}();
        console.log("account1 deposit balance after", account1Owner.balance);
        console.log("ep balance after", address(ep).balance);
        console.log(
            "account1 real deposit amount in ep shoule be 0, because has not prove.",
            account1.getDeposit()
        );
        vm.stopPrank();

        console.log("=== will execute prove to ep ===");
        vm.roll(10);
        {
            ITicketManager.Ticket[]
                memory depositTickets = new ITicketManager.Ticket[](1);
            ITicketManager.Ticket[]
                memory withdrawTickets = new ITicketManager.Ticket[](0);
            ITicketManager.Ticket memory account1OwnerTicket = ITicketManager
                .Ticket(address(account1), 10 ether, 1); // timestamp is 1.
            depositTickets[0] = account1OwnerTicket;
            ep.verifyBatchMock(
                depositTickets,
                withdrawTickets,
                payable(address(0x0)) // whatever beneficiary
            );

            console.log(
                "account1 real deposit amount in ep shoule be 10 ether, because has prove.",
                account1.getDeposit()
            );
            console.log(
                "account1 deposit balance after",
                account1Owner.balance
            );
        }
    }

    function account1OwnerWithdraw() public {
        console.log("=== account1Owner will withdraw to ep ===");
        {
            vm.startPrank(account1Owner);
            console.log(
                "account1 withdraw balance before",
                account1Owner.balance
            );
            console.log("ep balance before", address(ep).balance);
            account1.withdrawDepositTo(10 ether);
            console.log(
                "account1 withdraw balance after",
                account1Owner.balance
            );
            console.log("ep balance after", address(ep).balance);
            console.log(
                "account1 real deposit amount in ep shoule be 10, because has not prove.",
                account1.getDeposit()
            );
            vm.stopPrank();
        }

        console.log("=== will execute prove to ep ===");
        vm.roll(10);
        {
            ITicketManager.Ticket[]
                memory depositTickets = new ITicketManager.Ticket[](0);
            ITicketManager.Ticket[]
                memory withdrawTickets = new ITicketManager.Ticket[](1);
            ITicketManager.Ticket memory account1OwnerTicket = ITicketManager
                .Ticket(account1Owner, 10 ether, 1); // timestamp is 1.
            withdrawTickets[0] = account1OwnerTicket;
            ep.verifyBatchMock(
                depositTickets,
                withdrawTickets,
                payable(address(0x0)) // whatever beneficiary
            );

            console.log(
                "account1 real deposit amount in ep shoule be 0 ether, because has prove.",
                account1.getDeposit()
            );
            console.log(
                "account1 real withdraw balance after",
                account1Owner.balance
            );
        }
    }

    function account1OwnerExecuteTransfer() public {
        bytes memory data;
        vm.deal(address(account1), 2 ether);
        console.log(
            "account1 execute balance before: ",
            address(account1).balance
        );
        console.log(
            "account2Owner execute balance before: ",
            account2Owner.balance
        );
        vm.startPrank(account1Owner);
        account1.execute(account2Owner, 1 ether, data);
        vm.stopPrank();
        console.log(
            "account1 execute balance after: ",
            address(account1).balance
        );
        console.log(
            "account2Owner execute balance after: ",
            account2Owner.balance
        );
    }
}
