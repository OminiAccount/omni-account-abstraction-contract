// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

// import {Script, console} from "forge-std/Script.sol";
// import "contracts/core/EntryPoint.sol";
// import "contracts/core/SyncRouter.sol";
// import "test/Utils.sol";
// import "./Address.sol";

// contract DeploySyncRouter is Script, Utils, AddressHelper {
//     function run() external {
//         // Set up RPC URLs for both chains
//         string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
//         string memory arbitrumSepoliaRpc = vm.envString("CHAIN2_RPC_URL");

//         uint256 deployerPrivateKey = vm.envUint("DEPLOY");

//         vm.createSelectFork(sepoliaRpc);
//         vm.startBroadcast(deployerPrivateKey);
//         SyncRouter sepoliaSyncRouter = new SyncRouter(endPoint, owner);
//         console.log("sepoliaSyncRouter: ", address(sepoliaSyncRouter));
//         vm.stopBroadcast();

//         vm.createSelectFork(arbitrumSepoliaRpc);
//         vm.startBroadcast(deployerPrivateKey);
//         SyncRouter arbitrumSepoliaSyncRouter = new SyncRouter(endPoint, owner);
//         console.log(
//             "arbitrumSepoliaSyncRouter: ",
//             address(arbitrumSepoliaSyncRouter)
//         );
//         vm.stopBroadcast();
//     }
// }
