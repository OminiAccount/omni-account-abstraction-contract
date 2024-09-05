// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

contract ConfigManager {
    address public syncRouter;
    address public verifier;

    uint32[] public dstEids;

    modifier isOwner() {
        _isOwner();
        _;
    }

    modifier isSyncRouter() {
        require(msg.sender == syncRouter, "NEQSR");
        _;
    }

    function _isOwner() internal virtual {}

    function updateSyncRouter(address _syncRouter) external isOwner {
        syncRouter = _syncRouter;
    }

    function updateVerifier(address _verifier) external isOwner {
        verifier = _verifier;
    }

    function updateDstEids(uint32[] calldata _dstEids) external isOwner {
        dstEids = _dstEids;
    }
}
