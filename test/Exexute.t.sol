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

    bytes proofPublicValues =
        hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0b178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308d3b634a894b9aab4dd62ddea9416760d31b1eb7987bfa555e09338916930653300000000000000000000000000000000000000000000000000000000000005600000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000280000000000000000000000000046a62c69ef079a35a0060433d7e4d49c2ccd8560000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000ee4f5d9a8947fa1b80fcbd706eba2ba53fb71e25000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4b61d27f6000000000000000000000000c97e73b2770a0eb767407242fb3d35524fe229de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046a62c69ef079a35a0060433d7e4d49c2ccd8560000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000d3e96d74522afabba812c9199f74434c2ce7ffdb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000002e2f6e5e148000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000046a62c69ef079a35a0060433d7e4d49c2ccd8560000000000000000000000000000000000000000000000000429d069189e00000000000000000000000000000000000000000000000000000000000066dc7808000000000000000000000000046a62c69ef079a35a0060433d7e4d49c2ccd856000000000000000000000000000000000000000000000000058d15e1762800000000000000000000000000000000000000000000000000000000000066dc791c0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000046a62c69ef079a35a0060433d7e4d49c2ccd85600000000000000000000000000000000000000000000000002c68af0bb1400000000000000000000000000000000000000000000000000000000000066dc7940";

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
        vm.rollFork(6650143);
        bytes
            memory proof = hex"c430ff7f1865737e02476cbe163d0cc94c0820dcdd8a214ed86a64cd2b71aa9e25decf7826801677b6037347f8108b3175f07114f44a308a7c021e5ab43cc1ca6188c49a02a4462f3cdd38e50a743f6478d19b32c0328b3953e2a40735afd2ee3b32a2521632ea79700b4df6158ccfa3f1f2f31da8c8a6de9e8c6c248304183b2080916b04c19feb747dd7ec9f1c16492ae18254b0629086801753fb79e2e892725a9e9e164783e31f790dd49365c22f1a49c78c219f94295439a95b2b9b11dfb3b08b781f5cbc6e89ebab27a6c30db4fd0bfac56fc6aa32a98e22fdfdaefd0cee5cd4501db30921aa463e3aca91d883925b0f3dd8a5acbf87422f241bfe2e894ea3480904442a0109b8c0494a2bb6ec9bd1b5831f91d010b5df899e9ace291fccda6d392da7004c2e78ae25277640073ec44d6e3618b5aad248586070bfbf324a6ed9de13f03e1a0e3975a77034191b9e531c2d2c35722a8e6a33c24d8d49322cdbdf2b2ecae3f4bb094f5b1ffff05e524d281d13ae70c247b04923f7e39d73be9b1383106bb8e8bd0c3c6b8f78eb844862be6f6daa2627461c9cac4ae6f2c7907394bb041231b8b7a62254ceb305132f5b9f2cc87396602832ac00d7f2caf2deaf4f4b1bd8ba85fff98d4f9a52dced2a86e7155730c8cf1d1d8791050bc42df658a6630dad43d05778c8124820c5eebf3549317d0771ba22939d3c161b783141ac73331b5d2466acd5a83a4276716d33bad1db59f89d8ece8c8eb2ef6c03c8d82d1c612f88f4615861603b19920451f489bba4d0aa42a48d99243bedbeb8769cfd99c61ce232dcc570f37ad5388abda036cb77e62011ef318dde4f5516ff5da20f0315137a2b78fa975f8ca5aaa992279f7e17b8c49386963277d9dd120e0e9b58aa6e03ed9b2286ac9c1251bfc5629717bad46cc530aa1d6062844804b5e0b6dc447f051be2129936efeedd95d38b3791b2797936aa7addc08ba47f818938c56c10ad0cad2e127686ea83c4ae70b8bb6bf5bfcd69e7afd42a9955872b5b45b7d945232823effc2ef152f1cdb3f65e966094417c60f49ffa58876ce5f0459bad913df916e6408a3818f633a777a06e6f1b7a698b2520d7e2fd1bdfd457bf729df63f120ca90a08c5fbd3036ada20708a49352a7df8f0cd5b30c6fc20929ac220c3f9562a60e1b11fcae34cfdaf8d9315511b7d95fe9dec0e8f8456fe03386d31db82ab";

        vm.startPrank(owner);
        ep.verifyBatch{value: 154012374447005}(
            proof,
            proofPublicValues,
            payable(owner)
        );
        vm.stopPrank();
    }

    function test_syncBatch() public {
        bytes memory syncInfo = abi.encode(
            proofPublicValues,
            address(payable(owner))
        );
        vm.startPrank(arbitrumSepoliaSyncRouter);
        ep.syncBatch(syncInfo);
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
