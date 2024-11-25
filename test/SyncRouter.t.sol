// // SPDX-License-Identifier: GPL-3.0
// pragma solidity ^0.8.23;

// import "forge-std/console.sol";
// import "contracts/core/EntryPoint.sol";
// import "contracts/interfaces/ITicketManager.sol";
// import "contracts/interfaces/PackedUserOperation.sol";
// import "contracts/SimpleAccount.sol";
// import "contracts/SimpleAccountFactory.sol";
// import "contracts/core/SyncRouter.sol";
// import "./Utils.sol";

// contract SyncRouterTest is Utils {
//     uint256 sepoliaFork;

//     EntryPoint ep;
//     SimpleAccountFactory factory;

//     address deployer = address(0xa54753229AD35abC403B53E629A28820C8041eaA);

//     address account1Owner = address(0x01);
//     address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);
//     SimpleAccount account1;

//     SyncRouter router1;
//     SyncRouter router2;

//     function setUp() public {
//         string memory SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
//         sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
//         vm.selectFork(sepoliaFork);
//         // vm.rollFork(5_899_056);
//         vm.deal(deployer, 100 ether);
//         vm.deal(account1Owner, 20 ether);
//         vm.startPrank(deployer);
//         ep = new EntryPoint();
//         factory = new SimpleAccountFactory(ep);
//         account1 = factory.createAccount(account1Owner, 0);

//         router1 = new SyncRouter(
//             address(0x6EDCE65403992e310A62460808c4b910D972f10f),
//             deployer
//         );

//         router1.updateEntryPoint(address(ep));

//         ep.updateSyncRouter(address(router1));
//         uint32[] memory dstEids = new uint32[](1);
//         dstEids[0] = 40231;
//         ep.updateDstEids(dstEids);

//         router1.setPeer(dstEids[0], addressToBytes32(address(0x1234)));
//         vm.stopPrank();

//         console.log("ep address", address(ep));
//         console.log("factory address", address(factory));
//     }

//     function test_send() public {
//         account1OwnerDeposit();
//         console.log();
//         vm.deal(address(account1), 2 ether);
//         bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);

//         PackedUserOperation[] memory userOps = new PackedUserOperation[](2);
//         address sender = address(account1);
//         uint256 chainId = block.chainid;
//         bytes32 accountGasLimits = packUints(60000, 55000);
//         uint256 preVerificationGas = 16997;
//         uint256 mainChainGasPrice = 2500000000;
//         bytes32 gasFees = packUints(2500000000, 30000000000);
//         bytes memory paymasterAndData = "";
//         PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
//             sender,
//             chainId,
//             data,
//             mainChainGasPrice,
//             accountGasLimits,
//             preVerificationGas,
//             gasFees,
//             paymasterAndData,
//             account1Owner,
//             0
//         );
//         PackedUserOperation memory account1OwnerUserOp2 = PackedUserOperation({
//             sender: account1OwnerUserOp.sender,
//             chainId: 1,
//             callData: account1OwnerUserOp.callData,
//             mainChainGasPrice: mainChainGasPrice,
//             accountGasLimits: account1OwnerUserOp.accountGasLimits,
//             preVerificationGas: account1OwnerUserOp.preVerificationGas,
//             gasFees: account1OwnerUserOp.gasFees,
//             paymasterAndData: account1OwnerUserOp.paymasterAndData,
//             owner: account1OwnerUserOp.owner,
//              operationType:0
//         });
//         userOps[0] = account1OwnerUserOp;
//         userOps[1] = account1OwnerUserOp2;
//         vm.startPrank(deployer);
//         // ep.verifyBatchMockUserOp{value: 514197274447005}(
//         //     userOps,
//         //     payable(deployer)
//         // );
//         vm.stopPrank();
//         console.log(
//             "account1 execute balance after should be 1 ether: ",
//             address(account1).balance
//         );
//         console.log(
//             "account2Owner execute balance after should be 1 ether: ",
//             account2Owner.balance
//         );
//     }

//     function test_sync() public {
//         account1OwnerDeposit();
//         console.log();
//         vm.deal(address(account1), 2 ether);
//         bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);

//         PackedUserOperation[] memory userOps = new PackedUserOperation[](2);
//         address sender = address(account1);
//         uint256 chainId = block.chainid;
//         bytes32 accountGasLimits = packUints(60000, 55000);
//         uint256 preVerificationGas = 16997;
//         uint256 mainChainGasPrice = 2500000000;
//         bytes32 gasFees = packUints(2500000000, 30000000000);
//         bytes memory paymasterAndData = "";
//         PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
//             sender,
//             chainId,
//             data,
//             mainChainGasPrice,
//             accountGasLimits,
//             preVerificationGas,
//             gasFees,
//             paymasterAndData,
//             account1Owner,
//             0
//         );
//         PackedUserOperation memory account1OwnerUserOp2 = PackedUserOperation({
//             sender: account1OwnerUserOp.sender,
//             chainId: 1,
//             callData: account1OwnerUserOp.callData,
//             mainChainGasPrice: mainChainGasPrice,
//             accountGasLimits: account1OwnerUserOp.accountGasLimits,
//             preVerificationGas: account1OwnerUserOp.preVerificationGas,
//             gasFees: account1OwnerUserOp.gasFees,
//             paymasterAndData: account1OwnerUserOp.paymasterAndData,
//             owner: account1OwnerUserOp.owner,
//             operationType: 0
//         });
//         userOps[0] = account1OwnerUserOp;
//         userOps[1] = account1OwnerUserOp2;
//         bytes memory userOpsMessage = abi.encode(userOps);
//         bytes memory message = abi.encode(userOpsMessage, deployer);
//         vm.startPrank(address(router1));
//         ep.syncBatch(message);
//         vm.stopPrank();
//         console.log(
//             "account1 execute balance after should be 1 ether: ",
//             address(account1).balance
//         );
//         console.log(
//             "account2Owner execute balance after should be 1 ether: ",
//             account2Owner.balance
//         );
//     }

//     function account1OwnerDeposit() public {
//         vm.recordLogs();
//         console.log("=== account1Owner will deposit to ep ===");
//         vm.startPrank(account1Owner);
//         console.log(
//             "account1 deposit balance before should be 20 ether",
//             account1Owner.balance
//         );
//         console.log("ep balance before 0 ether", address(ep).balance);
//         account1.addDeposit{value: 10 ether}();
//         console.log(
//             "account1 deposit balance after 10 ether",
//             account1Owner.balance
//         );
//         console.log("ep balance after 10 ether", address(ep).balance);
//         vm.stopPrank();
//         Vm.Log[] memory entries = vm.getRecordedLogs();

//         (uint256 amount, uint256 timestamp) = abi.decode(
//             entries[0].data,
//             (uint256, uint256)
//         );

//         console.log("=== will execute prove to ep ===");
//         vm.roll(10);
//         {
//             ITicketManager.Ticket[]
//                 memory depositTickets = new ITicketManager.Ticket[](1);
//             ITicketManager.Ticket[]
//                 memory withdrawTickets = new ITicketManager.Ticket[](0);
//             ITicketManager.Ticket memory account1OwnerTicket = ITicketManager
//                 .Ticket(address(account1), amount, timestamp);
//             depositTickets[0] = account1OwnerTicket;
//             vm.startPrank(deployer);
//             // ep.verifyBatchMock(
//             //     depositTickets,
//             //     withdrawTickets,
//             //     payable(address(0x0)) // whatever beneficiary
//             // );
//             vm.stopPrank();
//             console.log(
//                 "account1 deposit balance after shoule be 10 ether",
//                 account1Owner.balance
//             );
//         }
//     }
// }
