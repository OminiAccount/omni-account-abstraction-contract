pragma solidity ^0.8.23;

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
import "contracts/interfaces/core/IConfigManager.sol";

contract DepositTest is Utils, AddressHelper {
    EntryPoint ep;
    ZKVizingAccountFactory factory;
    ZKVizingAccount account1;
    SyncRouter router;
    address deployer = owner;
    address account1Owner = address(0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5);
    address account2Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
        vm.startPrank(deployer);
        ep = new EntryPoint();
        router = new SyncRouter(
            address(0x0B5a8E5494DDE7039781af500A49E7971AE07a6b),
            address(0),
            address(0)
        );
        router.setMirrorEntryPoint(uint64(block.chainid), address(ep));
        uint64[] memory chainIds = new uint64[](1);
        chainIds[0] = uint64(block.chainid);
        IConfigManager.Config[] memory configs = new IConfigManager.Config[](1);
        configs[0].router = address(router);
        ep.updateChainConfigs(chainIds, configs);
        factory = new ZKVizingAccountFactory(ep);
        factory.updateBundler(deployer);
        account1 = factory.createAccount(account1Owner, 1);
        console.log("account %s", address(account1));
        vm.stopPrank();
        vm.deal(address(account1), 10 ether);
        console.log("ep address", address(ep));
        console.log("factory address", address(factory));
        console.log("account1 balance", address(account1).balance);
    }

    function test_depositLocal() public {
        console.log("account1 balance pre", account1.getPreGasBalance());
        uint256 amount = 0.2 ether;
        uint256 gasAmount = 0.01 ether;
        uint256 destChainExecuteUsedFee = 0.001 ether;

        uint256 crossFee = account1.estimateDepositRemoteCrossFee(
            1,
            gasAmount,
            destChainExecuteUsedFee,
            500000,
            1550000000,
            0,
            0,
            address(0)
        );
        account1.depositRemote{
            value: amount + gasAmount + crossFee + destChainExecuteUsedFee
        }(
            1,
            amount,
            gasAmount,
            destChainExecuteUsedFee,
            crossFee,
            500000,
            1550000000,
            0,
            0,
            address(0)
        );
        bytes
            memory data = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000000000000000000007a120000000000000000000000000000000000000000000000000000000005c631f800000000000000000000000000000000000000000000000000000000000006f64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000038d7ea4c68000000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064bb8ce5260000000000000000000000000256235933006c75716e1a34ae28708e4e869675000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000002386f26fc100000000000000000000000000000000000000000000000000000000000000000000";
        router.testReceiveMessage{value: gasAmount + destChainExecuteUsedFee}(
            data
        );

        console.log("account1 balance after", account1.getPreGasBalance());
    }

    function test_withdrawLocal() public {
        console.log("account1 balance pre", address(account1).balance);
        console.log("account balance pre", account1Owner.balance);
        uint256 amount = 0.2 ether;
        uint256 crossFee = account1.estimateWithdrawRemoteCrossFee(
            uint64(block.chainid),
            amount,
            account1Owner,
            500000,
            1550000000,
            0,
            0,
            address(0)
        );
        vm.startPrank(account1Owner);
        account1.withdrawRemote(
            uint64(block.chainid),
            amount,
            account1Owner,
            crossFee,
            500000,
            1550000000,
            0,
            0,
            address(0)
        );
        vm.stopPrank();

        bytes
            memory data = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fe000000000000000000000000000000000000000000000000000000000007a120000000000000000000000000000000000000000000000000000000005c631f800000000000000000000000000000000000000000000000000000000000066eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008efce81d1697064ed0a114ae3c897dec6a409a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018000000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000002c68af0bb14000000000000000000000000000096f3088fc6e3e4c4535441f5bc4d69c4ef3fe9c5";
        router.testReceiveMessage{value: amount}(data);
        console.log("account1 balance after", address(account1).balance);
        console.log("account balance after", account1Owner.balance);
    }
}
