// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/ITicketManager.sol";
import "contracts/interfaces/PackedUserOperation.sol";
import "contracts/SimpleAccount.sol";
import "contracts/SimpleAccountFactory.sol";
import "contracts/core/SyncRouter.sol";
import "./Utils.sol";
import "script/Address.sol";

contract SyncRouterTest is Utils, AddressHelper {
    uint256 sepoliaFork;
    EntryPoint ep;
    SimpleAccountFactory factory;
    SimpleAccount account1;
    address deployer = owner;
    address account1Owner = address(0x01);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    struct OutPut {
        PackedUserOperation[] userOps;
        bytes32 newSmtRoot;
        ITicketManager.Ticket[] depositTickets;
        ITicketManager.Ticket[] withdrawTickets;
    }

    function setUp() public {
        string memory SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
        vm.selectFork(sepoliaFork);
        ep = EntryPoint(sepoliaEntryPoint);
        factory = SimpleAccountFactory(sepoliaFactory);

        account1 = factory.createAccount(account1Owner, 0);

        assert(address(account1).balance == 0);

        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
    }

    function test_userop() public {
        account1OwnerDeposit();
        console.log();

        vm.deal(address(account1), 2 ether);

        bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        address sender = address(account1);
        uint256 chainId = block.chainid;
        bytes memory initCode = "";
        bytes32 accountGasLimits = packUints(40000, 55000);
        uint256 preVerificationGas = 17000;
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
            sender
        );
        userOps[0] = account1OwnerUserOp;
        vm.startPrank(owner);
        ep.verifyBatchMockUserOp{value: 146839574447005}(
            userOps,
            payable(owner)
        );
        vm.stopPrank();
    }

    function test_executeUserop() public {
        bytes
            memory proof = hex"c430ff7f1b01fe5bfcb8d634583b2f0f50dc15fc4381ec073ef3b25172bfeeed213f9356301687ec244d39c657dcbf49ebc31d0d5a15793d6b93a8b10b621644d2adbf821c68ffd7063c5859518d7b8ec5197c311af1f033c0a4573e22c3d803f687fae9073d83875d1ddcb24840bec161ce0efa3568204a7aa5c89a93e87b099817b4b6096cb68dd3014f1d6374953475a103c890a75ecc13d583088a460367974166fc0f4e563d3558507d5865b8fe6871ffaaaf4d14bb9ff7524ede283c139bded9602de692f658ca3448e800f95e0a8e091023386e8979542d336947952ffa59468f0c52634716f764491bf21db635255140dfaf75846cebe8ffe2bb2e5ee7d730232240b9c3d642203fa3f0fa896dcd7a6469df8293ef2a77cce9819a3a087e83f711f4d5f35b561791369c58c92ed972840626c94ec825642b2ae94967f12e6dd82c49aa97a26bed60b2f32ad94e7b61fdf31c17cb86923bffd4283ca3329ce275007816e5e751ccab45bc9efc617a750e158e100ddeac84bbc9f628e2a7db491301976ae220d266f5deedd4e3c7d5263c0fca88798adff88bc7a501183ff0b270260199d3ac7455baa90f0928458ab10f043662cce48ba43bcd2e9173e1a4b2c323b60a047883aefc4c29c4fce3088eebd0a38187a0062a54ab0330a55a6b4fe92dc6d86beba5023b5f5c369b7239e6e457beb378a27564e4f6679eaac74f02e7300b802345cd33e1fa3db1eab82f9fec01d731cb996275aceaf2cab4e83f83fa2de0f124fa85a88cf8938b905d2d1eb18e7060f8d014e6abe9287590c33742792f6b4d1ff6c634160cdc86058feae5ff99891c6364417a88e477749877d08857194277a5018262b8d54948b7da38e9634b1b64dc07855dc265700dbf0c50337f0fdf1f3c4dcade27329e3845d5649d94e8d0ce912c0638551e8e54f5129931d70712a4e123aae4694dc05d835dc119ec7a3bed2aa77b0256496bade36bff54c42f9a37336301b0dfedba23a44e346f61b4a6e22f948e88fd894b1340b414afde0bb003003fec0978321e574b6268c5e6fa08a62f82b5be96018389779d24c4a014bbb42ab31c78e5a51b41fbb3c1cf0bd188593590b7930f3afe12f9335a2f2916898dcdda2f8c3d37522e89cac0e85f0c1009917a6169ab5aa9bbfbe30b5c320e4f17bb7c9cfccb891cab3bd52b7bd4097f4fdabc0cecf6e2a069924fe90929";
        bytes
            memory proofPublicValues = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0b178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308ab4c0d337d67f973a06781822240d493f765649a9d25522bda1f5c13fb9ca60000000000000000000000000000000000000000000000000000000000000005600000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000280000000000000000000000000d09d22e15b8c387a023811e5c1021b441b8f0e5a0000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac000000000000000000000000007735940000000000000000000000000000000000000000000000000000000000000002200000000000000000000000006b05888d6525d381525f9891447b3ccdc11c1ad0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4b61d27f6000000000000000000000000c97e73b2770a0eb767407242fb3d35524fe229de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d09d22e15b8c387a023811e5c1021b441b8f0e5a0000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000ecbd466b911a5f5f2c7799d20fcd6e978d9d5d1600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000008e1bc9bf040000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000d09d22e15b8c387a023811e5c1021b441b8f0e5a000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000066dc6530000000000000000000000000d09d22e15b8c387a023811e5c1021b441b8f0e5a000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000066dc686c0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000d09d22e15b8c387a023811e5c1021b441b8f0e5a00000000000000000000000000000000000000000000000000038d7ea4c680000000000000000000000000000000000000000000000000000000000066dc6560";

        vm.startPrank(owner);
        ep.verifyBatch{value: 0.4 ether}(
            proof,
            proofPublicValues,
            payable(owner)
        );
        vm.stopPrank();
    }

    function account1OwnerDeposit() public {
        vm.recordLogs();
        console.log("=== account1Owner will deposit to ep ===");
        vm.startPrank(account1Owner);
        console.log("account1 deposit balance before should be 20 ether");
        assert(account1Owner.balance == 20 ether);
        console.log("ep balance before 0 ether");
        assert(address(ep).balance == 0 ether);
        account1.addDeposit{value: 10 ether}();
        console.log("account1 deposit balance after 10 ether");
        assert(account1Owner.balance == 10 ether);
        console.log("ep balance after 10 ether", address(ep).balance);
        assert(address(ep).balance == 10 ether);
        console.log(
            "account1 real deposit amount in ep shoule be 0 ether, because has not prove."
        );
        assert(account1.getDeposit() == 0 ether);

        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        (uint256 amount, uint256 timestamp) = abi.decode(
            entries[0].data,
            (uint256, uint256)
        );

        console.log("=== will execute prove to ep ===");
        vm.roll(10);
        {
            ITicketManager.Ticket[]
                memory depositTickets = new ITicketManager.Ticket[](1);
            ITicketManager.Ticket[]
                memory withdrawTickets = new ITicketManager.Ticket[](0);
            ITicketManager.Ticket memory account1OwnerTicket = ITicketManager
                .Ticket(address(account1), amount, timestamp);
            depositTickets[0] = account1OwnerTicket;
            vm.startPrank(deployer);
            ep.verifyBatchMock(
                depositTickets,
                withdrawTickets,
                payable(deployer)
            );
            vm.stopPrank();

            console.log(
                "account1 real deposit amount in ep shoule be 10 ether, because has prove."
            );
            assert(account1.getDeposit() == 10 ether);
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
                .Ticket(address(account1), 10 ether, 1); // timestamp is 1.
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
                address(account1).balance
            );
        }
    }
}
