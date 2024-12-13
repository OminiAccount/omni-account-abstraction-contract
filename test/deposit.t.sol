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

contract DepositTest is Utils, AddressHelper {
    address ep = 0x8fC8d44A586227F81f322a46d22b2a4A7b1D52c8;
    address payable account1 =
        payable(address(0x531AA14fd30Cd2852bC000aCdDf8Cbb102ED373f));

    function setUp() public {
        uint64 chainId = IEntryPoint(ep).getMainChainId();
        console.log("chainId %s", chainId);
        // vm.deal(deployer, 100 ether);
        // vm.deal(account1Owner, 20 ether);
        // // vm.deal(router, 2 ether);
        // vm.startPrank(deployer);
        // ep = new EntryPoint();
        // router = new SyncRouter(address(0), address(0), address(0));
        // gverifier = new Groth16Verifier();
        // ep.updateVerifier(address(gverifier));
        // // ep.updateSyncRouter(address(router));
        // router.setMirrorEntryPoint(uint64(block.chainid), address(ep));
        // factory = new ZKVizingAccountFactory(ep);
        // factory.updateBundler(deployer);
        // account1 = factory.createAccount(account1Owner);
        // console.log("account %s", address(account1));
        // vm.stopPrank();
        // vm.deal(address(account1), 1 ether);
        // console.log("ep address", address(ep));
        // console.log("factory address", address(factory));
        // console.log("account1 balance", address(account1).balance);
        // vm.startPrank(account1Owner);
        // ep.updateVerifier(address(gverifier));
        // vm.stopPrank();
    }

    function test_depositRemote() public {
        console.log(
            "account1 balance pre",
            ZKVizingAccount(account1).getPreGasBalance()
        );
        ZKVizingAccount(account1).depositRemote{value: 2 ether}(
            1,
            1 ether,
            0.2 ether,
            0.01 ether,
            50000,
            0.1 gwei,
            0,
            0,
            address(0)
        );
    }
}
