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
            memory proof = hex"c430ff7f12f2422eca640d83c71d651afcccd654edbe94dfda60266657646661b9e5276e04965dce7d594ebd63080ec5ae1903104370f933dc6631c779527077cd25d6ae0798d6bba95f1a48775f8bb6fd949301628c9af1197eeb07497523994c8969360a5a26187eefa84dab372dde8eea2c5d0b347d558ca97c564eee3bd1d3f9a0941dd8a25dff2bee38411cb0d4ac2a601e56f3f3fce302afcf515e83e660f7884511f8e43d167c4a8d258421cb38e40b119a2751d95839a823b9183e5ba6b2e5810aa58b08fb255c3b49e92660b477e4a6c7195bd5778daee5b5f41223421f97e9042fe0498df3c639846d195ea497cc431e00dd0e5faa7bb0e45f90b1f9d40f361eca7cbabc1d3333836e0845b68c96cc69c8ceb99d5fa5c73fc5be1e3cb3c90b1fcbebef3ba6fccfd44f65535fb72350235fbc7bd687a7985dfa9d0f6c25b6f22f4815d4a385f2cba4e508c820f357ea09a818af160b805a90f6f3bbd1df65341b6770ad874f5c37a1551f7a2f64e74eff4291001c18f00e7b2ea0b6b14a684f2a07be7a7e49890ca2c86e405b6c0029291967c2c8e0b7f215dbdb3fb3e7cd5421b8914dd5f84adcd586cb0870f03e12c342273ff64b7cce14d7da49cbb1b0ce0cc67722719062cb14c03e725d17ace2971c96a3e3d0f3b9b4d45eb43717276120bbd013c540e329fb65c33319eb74e8e18799bd72417dae6f8860deee638718210d115c67327a93023e3cfb0c86f672987ccc6a1e43aafe10fba7a2070190832abf561b40de03f13d49c53e9bdecd657b8a0bd3e07d7dbe2fc53f0652ea703702d2b3938cb007b79f3b97610c1c7cb9edf903aa41b67bfd34ba4718b57450a6022e9d1c85395f5d46d5fdbce37681e52c24c98039b8467e5615165f656857b819a76e1526465ecdad102cb5acb874056224f44126efcea2e431e8e28016020112d2499d7bd68d3252b95d3718de883ca7eadf436c337e4372e5c4b9e4dbd519091306044825c9ac783575097e3d846ceba61d4da320e66cc830485a9caab53727f813f16fac2beeba7fbe47e61d4fe01f29156dcc00700e29a4556d52b20eff0cd0e552b01e1bbc6b7f6f5e8b3c794c67f1726bcbec404e0b2264bd4fc74b9a1d8899ea5ad91a9cc3d66230d6926bb781e3f9f8b21261f59c7eb6fbbb2f337a0c72ee7eb1e949b8086f89c431d73f85d863e5ea0578f6d4a76d4da774f0c3e4";
        bytes
            memory proofPublicValues = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0b178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308030284c96e7b7ddc8ddad585448612c2d2d676c540a608775df29ead58a88c090000000000000000000000000000000000000000000000000000000000000540000000000000000000000000000000000000000000000000000000000000068000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000026000000000000000000000000093d53d2d8f0d623c5cbe46daa818177a450bd9f70000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000271416b45f6efa3edf6efdaca7ec6b81040b19a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000027916984c665f15041929b68451303136fa16653000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000093d53d2d8f0d623c5cbe46daa818177a450bd9f70000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000177bf0001b3c91091b499be6badefbb8dec46ec500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000027916984c665f15041929b68451303136fa16653000000000000000000000000000000000000000000000000002386f26fc10000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000fd63ed0566a782ef57f559c6f5f9afece486642300000000000000000000000000000000000000000000000000271471148780000000000000000000000000000000000000000000000000000000000066dab764000000000000000000000000fd63ed0566a782ef57f559c6f5f9afece48664230000000000000000000000000000000000000000000000000b1a2bc2ec5000000000000000000000000000000000000000000000000000000000000066dad27c00000000000000000000000093d53d2d8f0d623c5cbe46daa818177a450bd9f700000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000000000000066dad63c000000000000000000000000000000000000000000000000000000000000000100000000000000000000000093d53d2d8f0d623c5cbe46daa818177a450bd9f700000000000000000000000000000000000000000000000000470de4df8200000000000000000000000000000000000000000000000000000000000066dad63c";

        // OutPut memory out = abi.decode(proofPublicValues, (OutPut));
        // console.log("123");
        vm.startPrank(owner);
        ep.verifyBatch{value: 1146839574447005}(
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
                "account1 real deposit amount in ep shoule be 10 ether, because has prove.",
                account1.getDeposit()
            );
            console.log(
                "account1 deposit balance after shoule be 10 ether",
                account1Owner.balance
            );
        }
    }
}
