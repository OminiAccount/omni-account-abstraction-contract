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
    uint256 arbitrumSepoliaFork;
    EntryPoint ep;
    SimpleAccountFactory factory;
    SimpleAccount account1;
    address deployer = owner;
    address account1Owner = address(0x01);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    bytes proofPublicValues =
        hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0b178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de630844d54253017efdb30202126da462089a72ee4df641d5b558f0d44d155ee62894000000000000000000000000000000000000000000000000000000000000056000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002800000000000000000000000001b93c9b777007dd213c3478926e0d1cf5adbf1930000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac00000000000000000000000000773594000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000f9339d7b1464db7e0dac1a893d534b27aa5e026c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4b61d27f6000000000000000000000000c97e73b2770a0eb767407242fb3d35524fe229de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b93c9b777007dd213c3478926e0d1cf5adbf1930000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac000000000000000000000000007735940000000000000000000000000000000000000000000000000000000000000002000000000000000000000000008af3ce712e73f951bf88798b8c69063663a5899700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a50000000000000000000000000000000000000000000000000011c37937e080000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000001b93c9b777007dd213c3478926e0d1cf5adbf193000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000066dd3a840000000000000000000000001b93c9b777007dd213c3478926e0d1cf5adbf19300000000000000000000000000000000000000000000000002c68af0bb1400000000000000000000000000000000000000000000000000000000000066dd3aa800000000000000000000000000000000000000000000000000000000000000010000000000000000000000001b93c9b777007dd213c3478926e0d1cf5adbf193000000000000000000000000000000000000000000000000006a94d74f4300000000000000000000000000000000000000000000000000000000000066dd3ac0";

    struct OutPut {
        PackedUserOperation[] userOps;
        bytes32 newSmtRoot;
        ITicketManager.Ticket[] depositTickets;
        ITicketManager.Ticket[] withdrawTickets;
    }

    function setUp() public {
        string memory SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
        string memory ARBITRUM_SEPOLIA_RPC_URL = vm.envString(
            "ARBITRUM_SEPOLIA_RPC_URL"
        );
        arbitrumSepoliaFork = vm.createFork(ARBITRUM_SEPOLIA_RPC_URL);
        // vm.selectFork(arbitrumSepoliaFork);
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
        vm.rollFork(6653563);
        bytes
            memory proof = hex"c430ff7f08478eeaf1f73e7627bd1d771af37df4e8005eb192ad61b4eccd34abf982ac890f5017c0a718573fba90da05d4f8c46a10146ea6a5559dfd949a3d75f3a1190402ec6e4ad6e9f1fe00a7b8c54a2aeca9b65428eb1dc2847b587316fea571777610a10d71907658dc30f2968ab4c42b284ab4dca7158939d955607e56532ac1e125a2b80b8fa58f4f8a35a4881dee6f2007babb10e2f0a312811a9219b3d7b21b24e49fdba15901e59721abc13af0a39836914b3d2861afebe16271d0b5df8fbc17d285be487a2d90931065ca028632a6a29006115f64264df8ceb995571c0abb1dacff2fda24fcf5033eaeea253cbd3ebb2d7ed7767cad276a325f1ca6e000542510894168035cf691ca88d2975eb42a4624ba8abbd10443c23e9451604c1a1c04a0faab8090be32bdfc6244c0f926f97378aafc5080b14e0b662ca2a53bc7a109fee039402bd33f64a0d2b78b40ea5d15e7dbd3654b13e79e867e6a487cd36a0776ae46f852a430c1d50d7bb0e514015d96a4a43613fd27ceffcc739c7bc2cd01a338e625c7640ff4c740cfd859a3045f810e8cc55127b795ff0f06bbaca81d24a7ba205e944e134ba2b96c0d42a07ecd8fc18cb6002be67a77760b7cff6e6613ced0797a1976e80c23a6121ea1d17fbb99a30540b9f7f041089dff06f246aa1bd643ceddee98e17b6f5309b7ee5174fae50df7fb453cb0f80ebd8f8d2f4e720d83512f5f921a5d21058fee5423b671562bc9a2f5f6835a78390de21fcb69c2247a7be5e427eab1da92c93f444b4bd293314ce08c93072a1a37d2acc2f6dbdd0a853b8ac3166eed8314908de3182e97abdbd3d223a04f37ce866a40c4cc97c3159527035c3c43f0af50decd55fbb0187ca3280ac93ddb4f3cf93efe4e6f3e5a008c886e884dcb313968f63fea1068db7b94f78a8eeb27817c4be65bb12d7bec2a1224eb88039afdd762234fa0c6ff98f0cb9a26233c71b6d3888ff33b94fdc1027d291a4d3cc425af6385637c6ddc86fafcbfd0e98457abcc7db94bedda90ed2c333be40ada5888c84c43c54af388902ebe73dd2a0deaea722da345e464f2d22568f572c6974456aa1e579de7245d2e0002821c6aaf225e9f00ea05a66ff95124fa5f912342e98b04b4631d1b67777fdbc320b14abae466ecbcdbc13ce90d36079b8c30087bed7c825557cc771f5bee65d3ca6363331ca40c5c16387694bd9e";

        vm.startPrank(owner);
        ep.updateDstCoeffGas(50);
        ep.updateDstConGas(200000);
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
