// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/ITicketManager.sol";
import "contracts/interfaces/PackedUserOperation.sol";
import "contracts/SimpleAccount.sol";
import "contracts/SimpleAccountFactory.sol";

contract EntryPointTest is Test {
    EntryPoint ep;
    SimpleAccountFactory factory;

    address deployer = address(0xa54753229AD35abC403B53E629A28820C8041eaA);

    address account1Owner = address(0x01);
    address account2Owner = address(0x02);
    SimpleAccount account1;
    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
        vm.startPrank(deployer);
        ep = new EntryPoint();
        factory = new SimpleAccountFactory(ep);
        account1 = factory.createAccount(account1Owner, 0);
        vm.stopPrank();

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

    function test_account_execute_from_calldata() public {
        account1OwnerDeposit();
        console.log();
        vm.deal(address(account1), 2 ether);
        console.log(
            "account1 execute balance before should be 2 ether: ",
            address(account1).balance
        );
        console.log(
            "account2Owner execute balance before should be 0 ether: ",
            account2Owner.balance
        );
        vm.startPrank(account1Owner);
        bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);
        (bool success, ) = address(account1).call(data);
        require(success, "Call to execute function failed");
        vm.stopPrank();
        console.log(
            "account1 execute balance after should be 1 ether: ",
            address(account1).balance
        );
        console.log(
            "account2Owner execute balance after should be 1 ether: ",
            account2Owner.balance
        );
    }

    function test_ep_execute_transfer() public {
        account1OwnerDeposit();
        console.log();
        vm.deal(address(account1), 2 ether);
        bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);
        console.logBytes(data);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        address sender = address(account1);
        uint256 chainId = block.chainid;
        bytes memory initCode = "";
        bytes32 accountGasLimits = packUints(60000, 55000);
        uint256 preVerificationGas = 16997;
        bytes32 gasFees = packUints(2500000000, 30000000000);
        bytes memory paymasterAndData = "";
        PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
            sender,
            chainId,
            initCode,
            data,
            accountGasLimits,
            preVerificationGas,
            gasFees,
            paymasterAndData,
            account1Owner
        );
        userOps[0] = account1OwnerUserOp;
        vm.startPrank(deployer);
        ep.verifyBatchMockUserOp(userOps, payable(deployer));
        vm.stopPrank();
        console.log(
            "account1 execute balance after should be 1 ether: ",
            address(account1).balance
        );
        console.log(
            "account2Owner execute balance after should be 1 ether: ",
            account2Owner.balance
        );
    }

    function account1OwnerDeposit() public {
        console.log("=== account1Owner will deposit to ep ===");
        vm.startPrank(account1Owner);
        console.log(
            "account1 deposit balance before should be 20 ether",
            account1Owner.balance
        );
        console.log("ep balance before 0 ether", address(ep).balance);
        account1.addDeposit{value: 10 ether}();
        console.log(
            "account1 deposit balance after 10 ether",
            account1Owner.balance
        );
        console.log("ep balance after 10 ether", address(ep).balance);
        console.log(
            "account1 real deposit amount in ep shoule be 0 ether, because has not prove.",
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
            vm.startPrank(deployer);
            ep.verifyBatchMock(
                depositTickets,
                withdrawTickets,
                payable(address(0x0)) // whatever beneficiary
            );
            vm.stopPrank();

            console.log(
                "account1 real deposit amount in ep shoule be 10 ether, because has prove.",
                account1.getDeposit()
            );
            console.log(
                "account1 deposit balance after shoule be 10 ether",
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
            vm.startPrank(deployer);
            ep.verifyBatchMock(
                depositTickets,
                withdrawTickets,
                payable(address(0x0)) // whatever beneficiary
            );
            vm.stopPrank();

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
}
