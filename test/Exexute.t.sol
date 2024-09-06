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

    function setUp() public {
        string memory SEPOLIA_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
        sepoliaFork = vm.createFork(SEPOLIA_RPC_URL);
        vm.selectFork(sepoliaFork);
        ep = EntryPoint(sepoliaEntryPoint);
    }

    function test_userop() public {
        address account = address(0xCB726A5C2AB61fe8a901E8AB8372d9e90790DF65);
        address account2Owner = address(
            0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa
        );
        vm.deal(address(account), 2 ether);
        bytes memory data = encodeTransferCalldata(account2Owner, 1 ether);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        address sender = account;
        uint256 chainId = block.chainid;
        console.log("chainId", chainId);
        bytes
            memory initCode = hex"19b8495e7d3c0ff16592f67745a0c887d3d60a4d5fbfb9cf00000000000000000000000069299a9dfcc793e9780a0115bf3b45b4deca24630000000000000000000000000000000000000000000000000000000000000000";
        bytes32 accountGasLimits = packUints(260000, 55000);
        uint256 preVerificationGas = 17000;
        bytes32 gasFees = packUints(2500000000, 30000000000);
        bytes memory paymasterAndData = "";
        PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
            sender,
            chainId,
            initCode,
            "",
            accountGasLimits,
            preVerificationGas,
            gasFees,
            paymasterAndData,
            sender
        );
        userOps[0] = account1OwnerUserOp;
        vm.startPrank(owner);
        ep.verifyBatchMockUserOp{value: 514197274447005}(
            userOps,
            payable(owner)
        );
        vm.stopPrank();
    }
}
