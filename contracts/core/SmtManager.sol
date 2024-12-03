// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

contract SmtManager {
    bytes32 public smtRoot =
        0xb178c245c947ea7e21ecede07728941a6ab1b706143c06873baff8ebd6de6308;

    function updateSmtRoot(bytes32 oldSmtRoot, bytes32 newSmtRoot) public {
        require(oldSmtRoot == smtRoot, "NEQSR");
        require(newSmtRoot != bytes32(0), "NRIZ");
        smtRoot = newSmtRoot;
    }
}
