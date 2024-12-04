// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

contract ConfigManager {
    struct Config {
        address entryPoint;
    }
    error NumberIsNotEqual();

    address public syncRouter;
    address public verifier;

    mapping(uint64 => Config) public chainConfigs;

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

    function updateChainConfigs(
        uint64[] calldata _chainIds,
        Config[] calldata _config
    ) external isOwner {
        if (_chainIds.length != _config.length) {
            revert NumberIsNotEqual();
        }
        unchecked {
            for (uint256 i = 0; i < _chainIds.length; ) {
                chainConfigs[_chainIds[i]] = _config[i];
                ++i;
            }
        }
    }
}
