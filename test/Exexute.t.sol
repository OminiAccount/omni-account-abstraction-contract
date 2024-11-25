// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/IPreGasManager.sol";
import "contracts/interfaces/PackedUserOperation.sol";
import "contracts/SimpleAccount.sol";
import "contracts/core/UserOperationLib.sol";
import "contracts/SimpleAccountFactory.sol";
import "contracts/core/SyncRouter.sol";
import "./Utils.sol";
import "script/Address.sol";
import "contracts/interfaces/IEntryPoint.sol";

contract ExecuteTest is Utils, AddressHelper {
    EntryPoint ep;
    SimpleAccountFactory factory;
    SimpleAccount account1;
    address deployer = owner;
    address account1Owner = address(0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
        vm.startPrank(deployer);
        ep = new EntryPoint();
        factory = new SimpleAccountFactory(ep);
        account1 = factory.createAccount(account1Owner, 0);
        address mock_address = factory.getAccountAddress(account1Owner, 0);
        console.log("get mock %s", mock_address);
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
        uint64 nonce
    ) public pure returns (PackedUserOperation memory) {
        bytes memory data = encodeTransferCalldata(transferTo, 0.001 ether);
        uint256 operationValue = 0;
        uint256 mainChainGasLimit = 200000;
        uint256 destChainGasLimit = 0;
        uint256 zkVerificationGasLimit = 2200;
        uint256 mainChainGasPrice = 2500000000;
        uint256 destChainGasPrice = 0;
        PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
            0,
            operationValue,
            sender,
            nonce,
            uint64(chainId),
            data,
            mainChainGasLimit,
            destChainGasLimit,
            zkVerificationGasLimit,
            mainChainGasPrice,
            destChainGasPrice,
            owner
        );
        return account1OwnerUserOp;
    }

    function test_executeUserop() public {
        vm.deal(account1Owner, 20 ether);
        // vm.startPrank(deployer);

        PackedUserOperation[] memory ops = new PackedUserOperation[](64);
        ops[0] = deposit(account1Owner, payable(address(account1)), 0.2 ether);
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
                uint64(index + 1)
            );
        }

        IEntryPoint.BatchData[] memory batches = new IEntryPoint.BatchData[](1);
        batches[0].userOperations = ops;
        batches[0].oldStateRoot = bytes32(
            0xb178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308
        );
        batches[0].newStateRoot = bytes32(
            0x4493bc7f7ee5a764ea2fdf8b8043e63e20751d08b1b1a17667cb958724d8c4e7
        );
        vm.startPrank(deployer);
        // console.log("balance", address(ep1).balance);

        // console.log("basic fee", ep1.estimateSyncFee("", 400000));

        ep.verifyBatchMock{value: 0.01 ether}(batches, payable(owner)); // 558499499735571
        // 108633674447005
        // 148633574447005
        console.log("balance", account2Owner.balance);
        vm.stopPrank();
    }

    // function test_syncBatch() public {
    //     vm.selectFork(arbitrumSepoliaFork);
    //     vm.startPrank(deployer);
    //     address account = 0x01b7cA9d6B8Ac943185E107e4BE7430e5D90B5A5;
    //     console.log("account balance before", account.balance);
    //     EntryPoint ep1 = new EntryPoint();
    //     factory = new SimpleAccountFactory(ep1);
    //     SimpleAccount account11 = factory.createAccount(account, 1);
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
