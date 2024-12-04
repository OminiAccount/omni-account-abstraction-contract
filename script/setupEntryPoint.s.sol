// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";
import "./Address.sol";

contract SetupEntryPoint is Script, AddressHelper {
    function run() external {
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
        string memory arbitrumSepoliaRpc = vm.envString("CHAIN2_RPC_URL");

        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        // config verifier, SyncRouter, dstEids, dstCoeffGas, dstConGas

        vm.createSelectFork(sepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        EntryPoint(sepoliaEntryPoint).updateVerifier(verifier);
        EntryPoint(sepoliaEntryPoint).updateSyncRouter(sepoliaSyncRouter);
        // EntryPoint(sepoliaEntryPoint).updateDstEids(sepoliaDstEids);
        // EntryPoint(sepoliaEntryPoint).updateDstCoeffGas(dstCoeffGas);
        // EntryPoint(sepoliaEntryPoint).updateDstConGas(dstConGas);
        vm.stopBroadcast();

        // config SyncRouter
        // vm.createSelectFork(arbitrumSepoliaRpc);
        // vm.startBroadcast(deployerPrivateKey);
        // EntryPoint(arbitrumSepoliaEntryPoint).updateSyncRouter(
        //     arbitrumSepoliaSyncRouter
        // );
        // vm.stopBroadcast();
    }
}
