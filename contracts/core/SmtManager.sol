// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

contract SmtManager {
    bytes32 public smtRoot =
        0xd3b634a894b9aab4dd62ddea9416760d31b1eb7987bfa555e093389169306533;

    function updateSmtRoot(bytes32 oldSmtRoot, bytes32 newSmtRoot) internal {
        require(oldSmtRoot == smtRoot, "NEQSR");
        require(newSmtRoot != bytes32(0), "NRIZ");
        smtRoot = newSmtRoot;
    }
}
