// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

contract ConfigManager {
    address public syncRouter;
    address public verifier;

    uint32[] public dstEids;

    uint256 internal dstCoeffGas;
    uint256 internal dstConGas;

    modifier isOwner() {
        _isOwner();
        _;
    }

    modifier isSyncRouter() {
        require(msg.sender == syncRouter, "NEQSRR");
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

    function updateDstCoeffGas(uint256 _dstCoeffGas) external isOwner {
        dstCoeffGas = _dstCoeffGas;
    }

    function updateDstConGas(uint256 _dstConGas) external isOwner {
        dstConGas = _dstConGas;
    }
}
