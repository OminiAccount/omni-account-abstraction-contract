// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../../contracts/core/EntryPoint.sol";

contract DeployContract is Test {
    function deployEntryPoint() public returns (EntryPoint ret) {}
}
