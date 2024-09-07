// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/SimpleAccountFactory.sol";
import "contracts/core/EntryPoint.sol";
import "test/Utils.sol";
import "./Address.sol";

contract DeployAAFactory is Script, Utils, AddressHelper {
    function run() external {
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
        string memory arbitrumSepoliaRpc = vm.envString("CHAIN2_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        vm.createSelectFork(sepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        SimpleAccountFactory sepoliaFactory = new SimpleAccountFactory(
            EntryPoint(sepoliaEntryPoint)
        );
        console.log("sepoliaFactory address: ", address(sepoliaFactory));
        vm.stopBroadcast();

        vm.createSelectFork(arbitrumSepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        SimpleAccountFactory arbitrumSepoliaFactory = new SimpleAccountFactory(
            EntryPoint(arbitrumSepoliaEntryPoint)
        );
        console.log(
            "arbitrumSepoliaFactory address: ",
            address(arbitrumSepoliaFactory)
        );
        vm.stopBroadcast();
    }
}
