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

contract DeployTest is Utils {
    EntryPoint entryPoint;
    ZKVizingAccountFactory factory;
    ZKVizingAccount account1;
    Groth16Verifier verifier;
    SyncRouter syncRouter;
    StateManager state;
    address deployer = address(0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5);
    address account1Owner = address(0xe25A045cBC0407DB4743c9c5B8dcbdDE2021e3Aa);

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(account1Owner, 20 ether);
        vm.startPrank(deployer);

        entryPoint = new EntryPoint();
        console.log("entryPoint: ", address(entryPoint));

        syncRouter = new SyncRouter(
            address(0x0B5a8E5494DDE7039781af500A49E7971AE07a6b), //op 0x4577A9D09AE42913fC7c4e0fFD87E3C60CE3bb1b 0x0B5a8E5494DDE7039781af500A49E7971AE07a6b
            address(0),
            address(0)
        );

        console.log("syncRouter address: ", address(syncRouter));

        factory = new ZKVizingAccountFactory(
            entryPoint,
            0x83370B380f74ce34c72ABcb8B485E3Fa56907D46
        );
        console.log("factory address: ", address(factory));

        if (block.chainid == entryPoint.MAIN_CHAINID()) {
            verifier = new Groth16Verifier();
            console.log("verifier address: ", address(verifier));
            state = new StateManager(address(entryPoint));
            console.log("state address: ", address(state));
            state.updateVerifier(address(verifier));
            entryPoint.updateStateManager(address(state));
        }

        // config chainConfig
        IEntryPoint.Config memory config;
        config.router = address(syncRouter);
        config.entryPoint = address(entryPoint);
        entryPoint.updateChainConfig(421614, config); //421614 28516
        entryPoint.updateChainConfig(28516, config);
        entryPoint.updateChainConfig(11155420, config);

        // config setMirrorEntryPoint
        syncRouter.updateEntryPoint(address(entryPoint));
        vm.stopPrank();
    }
}
