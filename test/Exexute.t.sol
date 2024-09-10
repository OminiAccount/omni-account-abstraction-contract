// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/ITicketManager.sol";
import "contracts/interfaces/PackedUserOperation.sol";
import "contracts/SimpleAccount.sol";
import "contracts/core/UserOperationLib.sol";
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

    // bytes arbitrumProofPublicValues =
    //     hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a04493bc7f7ee5a764ea2fdf8b8043e63e20751d08b1b1a17667cb958724d8c4e77c8c20082c352dca58293e2e1e99478afd230e86728a99d357dfbc7afd7030d60000000000000000000000000000000000000000000000000000000000000560000000000000000000000000000000000000000000000000000000000000058000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000026000000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a87800000000000000000000000000000000000000000000000000000000000066eee0000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac0000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a87800000000000000000000000000000000000000000000000000000000000066eee0000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac0000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000022000000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4b61d27f600000000000000000000000059fb398996726fb8c7bee023ef733a5f0e86ce04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    bytes sepoliaProofPublicValues =
        hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0b178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de63084493bc7f7ee5a764ea2fdf8b8043e63e20751d08b1b1a17667cb958724d8c4e7000000000000000000000000000000000000000000000000000000000000056000000000000000000000000000000000000000000000000000000000000005e000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000026000000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a87800000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac0000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000084b61d27f600000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a87800000000000000000000000000000000000000000000000000000000000aa36a70000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000041eb000000000000000000000000000030d400000000000000000000000000000000000000000000000000000000000029810000000000000000000000006fc23ac0000000000000000000000000077359400000000000000000000000000000000000000000000000000000000000000022000000000000000000000000001b7ca9d6b8ac943185e107e4be7430e5d90b5a5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4b61d27f6000000000000000000000000c97e73b2770a0eb767407242fb3d35524fe229de000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004d09de08a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a878000000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000000000000066ddaf48000000000000000000000000000000000000000000000000000000000000000100000000000000000000000038bdb2abd66c00cbf05584a9717c1094181a8780000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000066ddaf6c";
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
        // vm.selectFork(sepoliaFork);
        // ep = EntryPoint(sepoliaEntryPoint);
        // factory = SimpleAccountFactory(sepoliaFactory);

        // account1 = factory.createAccount(account1Owner, 0);

        // assert(address(account1).balance == 0);

        // vm.deal(deployer, 100 ether);
        // vm.deal(account1Owner, 20 ether);
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
        ep.verifyBatchMockUserOp{value: 1565074779735571}(
            userOps,
            payable(owner)
        );
        vm.stopPrank();
    }

    function test_executeUserop() public {
        vm.selectFork(sepoliaFork);
        ep = EntryPoint(sepoliaEntryPoint);
        vm.rollFork(6655611);
        // bytes
        //     memory arbitrum_proof = hex"c430ff7f25ced099ce4e34f31d982c39a9bec4299848dcfbcd945fd007311682c889c22e2cc38013e7d9d9ff87bf82e5f402c2ff3d696b712ce03bb08de67e66a72fdee2115c47d818fd8320c8347dc247e299a4b1e0c444ac1b715a59d9b3e8dc08822c1a96381593baae775c8e9acf79b64f6f5c84af85332eb9fbe025b3a2712d86970e69114e29f453cc90b71d6ef4b4d5b335ec11ea72252e838c5dce972eea3945041df08535591d8c53d90c852bc0ac5f7dc38ff58b9c0da843bad45f384bc52f0a7cb6e374c82af8d75ca0827aa07b1d0ebe81ea6f3bdf04b1acfe47de7c7e2e2a12b85b4daffd54203c7445b23be2fa6b5bb068d5e437a8041553400efbabcc1e9641ec4435c4d7a0afde45056dd39df4f7cb5a3f4836390612e8b1873f4b1b1c49493ca0844fc7d74a2de28930d75ffb19f99485c24895b4440c1ae31e8d5e283cf7547debe77f4b93af0676659656a6df0f3a8d2f364104f0a476e34b3d550cf0759b0de481d4518fdaa61fb77346f6c1d2301cfbe09e68b29276e26855080a7eb006e8655a50c6dd1a46304add978cda1d71d4e009062b7472075cc6fe0f1e08a56d90938faf0521fda46dc688b648ab9bbd3ec170d8be2ac15a9bbac086240e6f88d1563c36a329fe47bbdcff537ff8a25b346024d4ebe43e14f10ecaa708ccbb739ec756ee28790d8eaa1dbe228779e766ed29f9f9f089ea627d0f583f283d178237ce8e0e6974a9299e20677353d968b276ad560e2ae46d061c12bd8f0c134c795cdebaa35f2abf0d06f85ed50436d7a18d57130e04a848c0767f34962d731e5a121349d7027c9c8e54c77c138ce1dbc22b6e6805f90f0bc39411b4de10bd74d727fbe4b13b21da9496f1f5e91cfe0e84780710db3929c9314242c2f309b767d489db57665071088384d1b2a96901c0c7414c55260b9edf74764dd0141d33a5c7679ef18623134adee19f9330e848a4eed850f86e9655982ab353af431c7721584e4362690b9f50e0b4e902fc12bde22ec6c39c01dc56947a1cf9ee1513525ef57e6bc56c8b8625497f8af0dcfad805de297dd16998bb296bc9bc736215d4952631731be98e9272973e1d1755d494d1982e30d2ae19919cb0e1018139138bb79000905860ac4065c3a8d6d938116d75e49373e6bf7793b1b897cfabcf106f723235ecd139b459cd1a2fefe903b8efe7de7e152ecc2a44b056adf98a1e";
        bytes
            memory sepolia_proof = hex"c430ff7f22e1b86a6794a0aeaf37dd3730533d469d6ca59685abe85de7ef9892449e938b27084791eccf4660929b04104b02a479b669d1035bb36cbfac849a99372f7cb4242fd2da369ab58696ac194eb49f56ec00f4376dd0b2508ee0ed9e374fbc290222c76624f2ace6622692c7d858af6d0952dc5469a08ed28d26dc78b058a4fded18ee95c15342b30330503a7677821a3728481f2ff78476a408adb6afd58985e212769f4ad5941d695fa959363fe53aa4b2148c3421158888537b4d47865747df21c1cdfe1d076f5a3f1a487e697a9f41fc2000f37936eb565ed0a599a6a7118d0d2e51a577422455073ff8afa85198ec3e234a6724a8d846d7a03f17b71cbae21fd08c08cb9eb72d87ea11591095470d21f6cb103f25450edd2970721b130780213d8493937edaaebbe1fbabacd5cfae0876dece33351aa9fd3e4e9bedba70cb01d5b075222ea0e120bd0865ab54f338facc9b8a322cab9a7fd7de16b890877f30526bdc733bd867fac3d12a5ecec468d84bd113ef2f54f3b4be09dff356dab61355efd82005a3ba2d1b3f93a5e1d12b2eb4c575ec2dba2197e1b1aa79865eaa09f5f33e7b02b2d570bc87fc5c4daaf1e795c175cb6ec40bc0986f04e30435d118971ffa7d71bc67f960cfc834b0f5bebd8c8efb3d8e57cc50bc6cba8efd2f5224ae0dfef5e4240dae799fb8f3e8b47446431a35dab2d109bbd7f653b76cb8190e02382db0a6dc521d67f63e82cdbd24c3e91b4d19be5a19dfc59ab8896553b2143b93620eecd677ba0140fe5f4b4f9aaf03641cae4d7349836f0a586cf141771b575855a219c7014fd247960bd0bbbd8ea967cbdeb4862ac1c7d36d9c59df1513256dbabcd4fd210af749a1aceb632b6e39231277c0cda1d281f7dd62b02d60226e562448f82e32862e886a424bb72f782ddc3c7eba152cf6e065a3977e5ba90aad476041ddcb22856bb3db3adf6cde9d3dc0e4e788fba21de74d9c5c731daa1844fbc42a711eccab32cba38729720cafbe86ef9d686515cbc87de2d86ed64424a43b87c14245d04fb7a4b15fcef3b05f0529f8e409917675832ead8fbbd8f5194b217f7c6a6841c8d9ef40ec0f66eafd8130e16ca6be2e2537228a2de549a117d4f6ddf922f07f41428abe87e843d97068cd45a30209a5c77e67fe438cc55815f86f52cfd8bd90b06f0d6ddf8a666953b2790180b1ed8a4385d371822b2594";
        // EntryPoint.ProofOutPut memory proofOutPut = abi.decode(
        //     sepoliaProofPublicValues,
        //     (EntryPoint.ProofOutPut)
        // );
        // uint256 verificationGasLimit;
        // uint256 callGasLimit;
        // uint256 maxFeePerGas;
        // (verificationGasLimit, callGasLimit) = UserOperationLib.unpackUints(
        //     proofOutPut.allUserOps[0].accountGasLimits
        // );
        // (, maxFeePerGas) = UserOperationLib.unpackUints(
        //     proofOutPut.allUserOps[0].gasFees
        // );
        // console.log("verificationGasLimit", verificationGasLimit);
        // console.log("callGasLimit", callGasLimit);
        // console.log(
        //     "preVerificationGas",
        //     proofOutPut.allUserOps[0].preVerificationGas
        // );
        // console.log("maxFeePerGas", maxFeePerGas);
        // {
        //     uint256 requiredGas = mUserOp.verificationGasLimit +
        //         mUserOp.callGasLimit +
        //         mUserOp.paymasterVerificationGasLimit +
        //         mUserOp.paymasterPostOpGasLimit +
        //         mUserOp.preVerificationGas;

        //     requiredPrefund = requiredGas * mUserOp.maxFeePerGas;
        // }
        vm.startPrank(owner);
        // ep.updateDstCoeffGas(50);
        // ep.updateDstConGas(200000);
        ep.verifyBatch{value: 1565074779735571}(
            sepolia_proof,
            sepoliaProofPublicValues,
            payable(owner)
        );
        ITicketManager.DepositInfo memory info = ep.getDepositInfo(
            address(0x38BDb2ABd66c00cBF05584a9717c1094181a8780)
        );
        console.log("info", info.deposit);
        vm.stopPrank();
    }

    function test_syncBatch() public {
        vm.startPrank(deployer);
        EntryPoint ep1 = new EntryPoint();
        ep1.updateSyncRouter(arbitrumSepoliaSyncRouter);
        vm.stopPrank();
        bytes memory syncInfo = abi.encode(
            sepoliaProofPublicValues,
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
