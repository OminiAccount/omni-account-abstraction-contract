// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {Script, console, stdJson} from "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ReadHelper is Script {
    struct AddressInfo {
        string Name;
        uint64 ChainId;
        address Address;
    }
    function readPre() public view returns (string memory) {
        string memory filePath = "script/setup/setup.json";
        string memory jsonContent = vm.readFile(filePath);
        return jsonContent;
        // uint64 chainId = 1;
        // address addressStr = vm.parseJsonAddress(
        //     jsonContent,
        //     ".VizingPad-MainNet.1.Address"
        // );
    }
    function readVizingPad(string memory net) public view returns (address) {
        string memory vizingPad = "VizingPad";
        string memory key = string(
            abi.encodePacked(
                ".",
                net,
                ".",
                vizingPad,
                ".",
                Strings.toString(block.chainid),
                ".",
                "Address"
            )
        );
        return vm.parseJsonAddress(readPre(), key);
    }
}
