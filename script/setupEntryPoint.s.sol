// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console, stdJson} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/ZKVizingAccountFactory.sol";
import "contracts/interfaces/core/IEntryPoint.sol";
import "contracts/core/SyncRouter/SyncRouter.sol";
// import "./Address.sol";

contract SetupEntryPoint is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        vm.startBroadcast(deployerPrivateKey);

        // setup chainConfig
        IEntryPoint.Config memory config;
        config.router = address(0x6CCd5BeB3814e3b488D55Cfe68752b80F231E0A0);
        config.entryPoint = address(0x77ba34f4125710A924e61C602E9Cd65E302631E9);
        EntryPoint(0x77ba34f4125710A924e61C602E9Cd65E302631E9)
            .updateChainConfig(421614, config); //421614 28516
        EntryPoint(0x77ba34f4125710A924e61C602E9Cd65E302631E9)
            .updateChainConfig(28516, config);
        EntryPoint(0x77ba34f4125710A924e61C602E9Cd65E302631E9)
            .updateChainConfig(11155420, config);
        // setup vizing receive (deposit)
        // SyncRouter(payable(0x6CCd5BeB3814e3b488D55Cfe68752b80F231E0A0))
        //     .setMirrorEntryPoint(
        //         421614,
        //         0x77ba34f4125710A924e61C602E9Cd65E302631E9
        //     );
        // SyncRouter(payable(0x6CCd5BeB3814e3b488D55Cfe68752b80F231E0A0))
        //     .setMirrorEntryPoint(
        //         28516,
        //         0x77ba34f4125710A924e61C602E9Cd65E302631E9
        //     );
        // SyncRouter(payable(0x6CCd5BeB3814e3b488D55Cfe68752b80F231E0A0))
        //     .setMirrorEntryPoint(
        //         11155420,
        //         0x77ba34f4125710A924e61C602E9Cd65E302631E9
        //     );
        // console
        // address _router = EntryPoint(0x3405407426ECF0026a85B367018E684c86710D9c)
        //     .getChainConfigs(421614)
        //     .router;
        // console.log(_router);
        // string memory aa = jsonContent.readString(".VizingPad-MainNet");
        // string memory ab = aa.readString(".1");
        // string memory addressStr = ab.readString(".Address");
        // string memory addressStr = stdJson.readString(
        //     jsonContent,
        //     string(abi.encodePacked(typeKey, ".", networkKey, ".", addressKey))
        // );
        // console.log(addressStr);
        // EntryPoint(sepoliaEntryPoint).updateDstEids(sepoliaDstEids);
        // EntryPoint(sepoliaEntryPoint).updateDstCoeffGas(dstCoeffGas);
        // EntryPoint(sepoliaEntryPoint).updateDstConGas(dstConGas);
        // vm.stopBroadcast();
        // config SyncRouter
        // vm.createSelectFork(arbitrumSepoliaRpc);
        // vm.startBroadcast(deployerPrivateKey);
        // EntryPoint(arbitrumSepoliaEntryPoint).updateSyncRouter(
        //     arbitrumSepoliaSyncRouter
        // );
        vm.stopBroadcast();
    }
}
