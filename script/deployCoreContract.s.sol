// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/core/StateManager.sol";
import "contracts/verifiers/Groth16Verifier.sol";
import "contracts/core/SyncRouter/SyncRouter.sol";
import "contracts/ZKVizingAccountFactory.sol";
import "contracts/core/ZKVizingAADataHelp.sol";
import "./readHelper.sol";

contract DeployCoreContract is ReadHelper {
    function run() external {
        // only deployed on vizing
        Groth16Verifier verifier;
        StateManager state;

        uint256 deployerPrivateKey = vm.envUint("DEPLOY");
        string memory netMode = vm.envString("NETMODE");

        vm.startBroadcast(deployerPrivateKey);

        address vizingPad = readVizingPad(netMode);
        console.log("vizingPad: ", vizingPad);

        EntryPoint entryPoint = new EntryPoint();
        console.log("entryPoint: ", address(entryPoint));

        SyncRouter syncRouter = new SyncRouter(
            address(readVizingPad(netMode)), //op 0x4577A9D09AE42913fC7c4e0fFD87E3C60CE3bb1b 0x0B5a8E5494DDE7039781af500A49E7971AE07a6b
            address(0),
            address(0)
        );

        console.log("syncRouter address: ", address(syncRouter));

        ZKVizingAccountFactory factory = new ZKVizingAccountFactory(
            entryPoint,
            0x83370B380f74ce34c72ABcb8B485E3Fa56907D46
        );
        console.log("factory address: ", address(factory));

        ZKVizingAADataHelp helper = new ZKVizingAADataHelp();
        console.log("helper address: ", address(helper));

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
        entryPoint.updateChainConfig(421614, config);
        entryPoint.updateChainConfig(28516, config);
        entryPoint.updateChainConfig(11155420, config);

        // config setMirrorEntryPoint
        syncRouter.updateEntryPoint(address(entryPoint));

        vm.stopBroadcast();
    }
}
