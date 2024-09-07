// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/EntryPoint.sol";

contract DeployEntryPoint is Script {
    function run() external {
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
        string memory arbitrumSepoliaRpc = vm.envString("CHAIN2_RPC_URL");

        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        // vm.createSelectFork(sepoliaRpc);
        // vm.startBroadcast(deployerPrivateKey);
        // EntryPoint sepoliaEntryPoint = new EntryPoint();
        // console.log("sepoliaEntryPoint: ", address(sepoliaEntryPoint));

        // vm.stopBroadcast();

        vm.createSelectFork(arbitrumSepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        EntryPoint arbitrumSepoliaEntryPoint = new EntryPoint();
        console.log(
            "arbitrumSepoliaEntryPoint: ",
            address(arbitrumSepoliaEntryPoint)
        );
        vm.stopBroadcast();
    }
}
