// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

contract SmtManager {
    bytes32 public smtRoot;

    function updateSmtRoot(bytes32 newSmtRoot) internal {
        require(newSmtRoot != bytes32(0), "NRIZ");
        smtRoot = newSmtRoot;
    }
}
