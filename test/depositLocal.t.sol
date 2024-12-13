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
        account1.depositGasRemote{value: 2 ether}(
            1,
            0.2 ether,
            0.01 ether,
            500000,
            1550000000,
            0,
            0,
            address(0)
        );
    }
}
