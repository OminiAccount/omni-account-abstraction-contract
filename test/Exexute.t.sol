// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/core/IPreGasManager.sol";
import "contracts/ZKVizingAccount.sol";
import "contracts/libraries/UserOperationLib.sol";
import "contracts/ZKVizingAccountFactory.sol";
import "contracts/core/SyncRouter/SyncRouter.sol";
import "contracts/core/StateManager.sol";
import "./Utils.sol";
import "script/Address.sol";
import "contracts/interfaces/core/IEntryPoint.sol";
import "contracts/verifiers/Groth16Verifier.sol";

contract ExecuteTest is Utils, AddressHelper {
    EntryPoint ep;
    ZKVizingAccountFactory factory;
    ZKVizingAccount account1;
    Groth16Verifier gverifier;
    SyncRouter router;
    StateManager state;
    address deployer = owner;
    address account1Owner = address(0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
        // vm.deal(router, 2 ether);
        vm.startPrank(deployer);

        ep = new EntryPoint();
        gverifier = new Groth16Verifier();
        state = new StateManager(address(ep));

        state.updateVerifier(address(gverifier));

        ep.updateStateManager(address(state));

        router = new SyncRouter(address(0), address(0), address(0));

        router.updateEntryPoint(address(ep));
        factory = new ZKVizingAccountFactory(ep, deployer);

        account1 = factory.createAccount(account1Owner, 1);
        console.log("account %s", address(account1));
        vm.stopPrank();
        vm.deal(address(account1), 1 ether);
        console.log("ep address", address(ep));
        console.log("factory address", address(factory));
        console.log("account1 balance", address(account1).balance);
    }

    function getUserOp(
        address sender,
        address owner,
        uint256 chainId,
        address transferTo,
        uint64 nonce,
        bool inExec
    ) public pure returns (PackedUserOperation memory) {
        bytes memory data = encodeTransferCalldata(transferTo, 0.001 ether);
        uint256 operationValue = 0;
        uint64 mainChainGasLimit = 200_000;
        uint64 destChainGasLimit = 0;
        uint64 zkVerificationGasLimit = 2200;
        uint64 mainChainGasPrice = 2_500_000_000;
        uint64 destChainGasPrice = 0;
        ExecData memory exec = ExecData(
            nonce,
            uint64(chainId),
            mainChainGasLimit,
            destChainGasLimit,
            zkVerificationGasLimit,
            mainChainGasPrice,
            destChainGasPrice,
            data
        );
        ExecData memory innerExec;
        if (inExec) {
            innerExec = ExecData(
                nonce,
                uint64(2),
                mainChainGasLimit,
                destChainGasLimit,
                zkVerificationGasLimit,
                mainChainGasPrice,
                destChainGasPrice,
                data
            );
        }
        // ExecData memory innerExec = ExecData(
        //     nonce,
        //     uint64(2),
        //     mainChainGasLimit,
        //     destChainGasLimit,
        //     zkVerificationGasLimit,
        //     mainChainGasPrice,
        //     destChainGasPrice,
        //     data
        // );
        PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
            0,
            0,
            operationValue,
            sender,
            owner,
            exec,
            innerExec
        );
        return account1OwnerUserOp;
    }

    function test_executeUserop() public {
        vm.deal(account1Owner, 20 ether);
        // vm.startPrank(deployer);
        IEntryPoint.BatchData[] memory batches = new IEntryPoint.BatchData[](2);
        {
            PackedUserOperation[] memory ops = new PackedUserOperation[](64);
            ops[0] = deposit(
                account1Owner,
                payable(address(account1)),
                0.2 ether
            );
            ops[1] = withdraw(
                account1Owner,
                payable(address(account1)),
                0.05 ether
            );
            for (uint256 index = 2; index < 64; index++) {
                ops[index] = getUserOp(
                    address(account1),
                    account1Owner,
                    block.chainid,
                    account2Owner,
                    uint64(index + 1),
                    false
                );
            }

            batches[0].userOperations = ops;
            batches[0]
                .accInputHash = 0xa5845b8fb4b7b68fe9686342e9b54d5850f20e1d256db4d6553c5e309cb7ab12;
        }

        {
            PackedUserOperation[] memory ops = new PackedUserOperation[](64);
            for (uint256 index = 0; index < 64; index++) {
                bool inExec = index == 63 ? true : false;
                ops[index] = getUserOp(
                    address(account1),
                    account1Owner,
                    block.chainid,
                    account2Owner,
                    uint64(65 + index),
                    inExec
                );
            }

            batches[1].userOperations = ops;
            batches[1]
                .accInputHash = 0x2b716e4c655ea1976aaddc63b51735f24243cf04ab5bdb888489458839737e6a;
        }

        vm.startPrank(deployer);
        // console.log("balance", address(ep1).balance);

        // console.log("basic fee", ep1.estimateSyncFee("", 400000));
        IEntryPoint.ChainsExecuteInfo memory chainsExecuteInfo;
        chainsExecuteInfo.beneficiary = payable(owner);
        IEntryPoint.ChainExecuteExtra[]
            memory extras = new IEntryPoint.ChainExecuteExtra[](1);
        extras[0].chainId = uint64(block.chainid);
        extras[0].chainFee = 0;
        extras[0].chainUserOperationsNumber = 128;
        chainsExecuteInfo.chainExtra = extras;
        chainsExecuteInfo
            .newStateRoot = 0x9e664fd150d91a900ff82407dc45afd52863d0a211d0daec25e870e96e4e227b;
        bytes
            memory proof = hex"03bb71a88f4c3a2e38e59f56a922839c7a42ad5561d3b8127df47c6362366a95244b6a715355a651635c04bda44a5b908ce427e0723372a9d49d2484fc893d1c2e24204d5a6fe51d88f228e944bea2e554e4d14dad103f508773666c8ebbaaac1521a28cbdc16455f7d8bfed7c73f37a829f676569c1f8d9bbf2cdf8a027b4bf0c66cbc9d7afb62da9ca541d191c30c6b68c40e87ae0409db7c7f181b14a27c21776bf99e65e66e906cf6a7061ebaeb9d41442ff7e93da0f8002f8d57cb7b2f32dbe9278ce3755984bcbbe7374d06fed1c07982ce3a485b843b63802cff3dcee0d769f7cdb4fcfe4f225e4faaa33093a90dfed4d0321e92081ea9d820da3a12e";
        ep.verifyBatches{value: 0.01 ether}(proof, batches, chainsExecuteInfo);
        console.log("balance", account2Owner.balance);
        vm.stopPrank();
    }

    // function test_depositGasRemote() public {
    //     console.log("account1 balance pre", account1.getPreGasBalance());

    //     ep.estimateSubmitDepositOperationByRemoteGas{value: 1 ether}(
    //         address(account1),
    //         1 ether,
    //         1
    //     );

    //     bytes memory data = abi.encodeCall(
    //         EntryPoint.submitDepositOperationByRemote,
    //         (address(account1), 1 ether, 1)
    //     );

    //     CrossMessageParams memory params;
    //     CrossETHParams memory crossETH;
    //     crossETH.amount = 1 ether;
    //     // crossETH.reciever = address(ep);
    //     params._hookMessageParams.way = 255;
    //     params._hookMessageParams.packCrossMessage = data;
    //     params._hookMessageParams.packCrossParams = abi.encode(crossETH);
    //     params._hookMessageParams.destChainExecuteUsedFee = 5000;
    //     (, bytes memory paramsData) = router.getUserOmniEncodeMessage(params);
    //     // router.testReceiveMessage{value: 3 ether}(paramsData);

    //     console.log("account1 balance after", account1.getPreGasBalance());
    // }

    // function test_syncBatch() public {
    //     vm.selectFork(arbitrumSepoliaFork);
    //     vm.startPrank(deployer);
    //     address account = 0x01b7cA9d6B8Ac943185E107e4BE7430e5D90B5A5;
    //     console.log("account balance before", account.balance);
    //     EntryPoint ep1 = new EntryPoint();
    //     factory = new ZKVizingAccountFactory(ep1);
    //     ZKVizingAccount account11 = factory.createAccount(account, 1);
    //     vm.deal(address(account11), 0.1 ether);
    //     ep1.updateSyncRouter(arbitrumSepoliaSyncRouter);
    //     ep1.updateSmtRoot(
    //         bytes32(
    //             0xb178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308
    //         ),
    //         bytes32(
    //             0x4493bc7f7ee5a764ea2fdf8b8043e63e20751d08b1b1a17667cb958724d8c4e7
    //         )
    //     );
    //     IEntryPoint.ProofOutPut memory proofOutPut = abi.decode(
    //         arbitrumProofPublicValues,
    //         (IEntryPoint.ProofOutPut)
    //     );
    //     proofOutPut.allUserOps[0].sender = address(account11);
    //     proofOutPut.allUserOps[1].sender = address(account11);
    //     proofOutPut.allUserOps[0].owner = account;
    //     proofOutPut.allUserOps[1].owner = account;
    //     bytes memory publicValues = abi.encode(proofOutPut);
    //     bytes memory syncInfo = abi.encode(
    //         publicValues,
    //         address(payable(owner))
    //     );
    //     vm.startPrank(arbitrumSepoliaSyncRouter);
    //     ep1.syncBatch(syncInfo);
    //     console.log("account balance after", account.balance);
    //     vm.stopPrank();
    // }
}
