// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "forge-std/console.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/interfaces/core/IPreGasManager.sol";
import "contracts/ZKVizingAccount.sol";
import "contracts/libraries/UserOperationLib.sol";
import "contracts/ZKVizingAccountFactory.sol";
import "contracts/core/SyncRouter/SyncRouter.sol";
import "./Utils.sol";
import "script/Address.sol";
import "contracts/interfaces/core/IEntryPoint.sol";
import "contracts/interfaces/core/BaseStruct.sol";
import "contracts/interfaces/core/IConfigManager.sol";

contract DepositTest is Utils, AddressHelper {
    EntryPoint ep;
    address deployer = 0x8bd295E672D74a868795406A1a5546B2A6da3Bf7;
    address account1Owner = address(0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    function setUp() public {
        ep = EntryPoint(0x77ba34f4125710A924e61C602E9Cd65E302631E9);
        console.log("mainChain %s", ep.MAIN_CHAINID());
    }

    function test_verifyBatch() public {
        bytes
            memory proof = hex"03bb71a88f4c3a2e38e59f56a922839c7a42ad5561d3b8127df47c6362366a95244b6a715355a651635c04bda44a5b908ce427e0723372a9d49d2484fc893d1c2e24204d5a6fe51d88f228e944bea2e554e4d14dad103f508773666c8ebbaaac1521a28cbdc16455f7d8bfed7c73f37a829f676569c1f8d9bbf2cdf8a027b4bf0c66cbc9d7afb62da9ca541d191c30c6b68c40e87ae0409db7c7f181b14a27c21776bf99e65e66e906cf6a7061ebaeb9d41442ff7e93da0f8002f8d57cb7b2f32dbe9278ce3755984bcbbe7374d06fed1c07982ce3a485b843b63802cff3dcee0d769f7cdb4fcfe4f225e4faaa33093a90dfed4d0321e92081ea9d820da3a12e";
        IEntryPoint.BatchData[] memory batchDatas = new IEntryPoint.BatchData[](
            2
        );
        bytes memory data;

        // 1 batch
        {
            PackedUserOperation[] memory ops = new PackedUserOperation[](1);

            // 1 op
            ExecData memory exec = ExecData(1, 28516, 10, 10, 10, 20, 20, data);
            ExecData memory innerExec;
            ops[0] = PackedUserOperation(
                0,
                1,
                20000000000000000,
                0x322478ba2ffD32ddE6dc8a518A8b52922C3b9B0B,
                0x7c38C1646213255f62dB509688B8fA062e0Ed8e4,
                exec,
                innerExec
            );
            batchDatas[0].userOperations = ops;
            batchDatas[0]
                .accInputHash = 0xa5845b8fb4b7b68fe9686342e9b54d5850f20e1d256db4d6553c5e309cb7ab12;
        }

        // 2 batch
        {
            PackedUserOperation[] memory ops = new PackedUserOperation[](2);

            // 1 op
            ExecData memory exec = ExecData(2, 28516, 10, 10, 10, 20, 20, data);
            ExecData memory innerExec;
            ops[0] = PackedUserOperation(
                0,
                2,
                2000000000000000,
                0x322478ba2ffD32ddE6dc8a518A8b52922C3b9B0B,
                0x7c38C1646213255f62dB509688B8fA062e0Ed8e4,
                exec,
                innerExec
            );

            // 2 op
            ExecData memory exec1 = ExecData(
                3,
                28516,
                10,
                10,
                10,
                20,
                20,
                data
            );
            ops[1] = PackedUserOperation(
                0,
                1,
                2000000000000000,
                0x322478ba2ffD32ddE6dc8a518A8b52922C3b9B0B,
                0x7c38C1646213255f62dB509688B8fA062e0Ed8e4,
                exec,
                innerExec
            );
            batchDatas[1].userOperations = ops;
            batchDatas[1]
                .accInputHash = 0x2b716e4c655ea1976aaddc63b51735f24243cf04ab5bdb888489458839737e6a;
        }
        IEntryPoint.ChainExecuteExtra[]
            memory chainExecuteExtras = new IEntryPoint.ChainExecuteExtra[](1);
        chainExecuteExtras[0] = BaseStruct.ChainExecuteExtra(
            28516,
            1500000000000000,
            3
        );
        IEntryPoint.ChainsExecuteInfo memory chainsExecuteInfo = BaseStruct
            .ChainsExecuteInfo(
                chainExecuteExtras,
                0x9e664fd150d91a900ff82407dc45afd52863d0a211d0daec25e870e96e4e227b,
                0x83370B380f74ce34c72ABcb8B485E3Fa56907D46
            );

        vm.startPrank(deployer);

        ep.verifyBatches(proof, batchDatas, chainsExecuteInfo);
        vm.stopPrank();
    }
}
