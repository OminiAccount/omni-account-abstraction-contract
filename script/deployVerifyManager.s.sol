// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "contracts/core/VerifyManager.sol";
import "test/Utils.sol";
import "./Address.sol";

contract DeploySyncRouter is Script, Utils, AddressHelper {
    function run() external {
        string memory sepoliaRpc = vm.envString("CHAIN1_RPC_URL");
        uint256 deployerPrivateKey = vm.envUint("DEPLOY");

        vm.createSelectFork(sepoliaRpc);
        vm.startBroadcast(deployerPrivateKey);
        VerifyManager verify = new VerifyManager(sp1Verifier, aaProgramVKey);
        conosle.log("verify address: ", address(verify));
        vm.stopBroadcast();
    }
}
