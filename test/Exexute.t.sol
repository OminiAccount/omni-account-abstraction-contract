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

contract SyncRouterTest is Utils {
    function setUp() public {}

    function test_userop() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](2);
        // [["0x0000000000000000000000000000000000000001",11155111,"0x5fbfb9cf00000000000000000000000069299a9dfcc793e9780a0115bf3b45b4deca24630000000000000000000000000000000000000000000000000000000000000000","0x","0x00000000000000000000000000006978000000000000000000000000000088b8",17000,"0x0000000000000000000000009502f900000000000000000000000006fc23ac00","0x","0x0000000000000000000000000000000000000001"]]
        address sender = address(0x01);
        console.logAddress(sender);
        uint256 chainId = 11155111;
        bytes
            memory initCode = "0x5fbfb9cf00000000000000000000000069299a9dfcc793e9780a0115bf3b45b4deca24630000000000000000000000000000000000000000000000000000000000000000";
        bytes32 accountGasLimits = packUints(27000, 35000);
        console.logBytes32(accountGasLimits);
        uint256 preVerificationGas = 17000;
        bytes32 gasFees = packUints(2500000000, 30000000000);
        console.logBytes32(gasFees);
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
    }
}
