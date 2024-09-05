// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/core/SyncRouter.sol";
import "test/Utils.sol";
import "./Address.sol";

contract SetupSyncRouter is Script, Utils, AddressHelper {
    function run() external {
        // Set up RPC URLs for both chains
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
        string memory arbitrumSepoliaRpc = vm.envString("CHAIN2_RPC_URL");

        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        vm.createSelectFork(arbitrumSepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        SyncRouter(arbitrumSepoliaSyncRouter).setPeer(
            sepoliaEid,
            addressToBytes32(address(sepoliaSyncRouter))
        );
        // config entrypoint address
        SyncRouter(arbitrumSepoliaSyncRouter).updateEntryPoint(
            arbitrumSepoliaEntryPoint
        );
        vm.stopBroadcast();

        vm.createSelectFork(sepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        SyncRouter(sepoliaSyncRouter).setPeer(
            arbitrumSepoliaEid,
            addressToBytes32(address(arbitrumSepoliaSyncRouter))
        );
        // config entrypoint address
        SyncRouter(sepoliaSyncRouter).updateEntryPoint(sepoliaEntryPoint);
        vm.stopBroadcast();
    }
}
