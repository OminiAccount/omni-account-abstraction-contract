// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";
import "./Address.sol";

contract SetupEntryPoint is Script, AddressHelper {
    function run() external {
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");

        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        // config verifier, SyncRouter, dstEids

        vm.createSelectFork(sepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        EntryPoint(sepoliaEntryPoint).updateVerifier(verifier);
        EntryPoint(sepoliaEntryPoint).updateSyncRouter(sepoliaSyncRouter);
        EntryPoint(sepoliaEntryPoint).updateDstEids(sepoliaDstEids);

        vm.stopBroadcast();
    }
}
