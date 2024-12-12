// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import "../interfaces/core/IConfigManager.sol";

contract ConfigManager is IConfigManager {
    error NumberIsNotEqual();

    uint64 internal constant MAIN_CHAINID = 31337;

    address public syncRouter;
    address public verifier;

    mapping(uint64 => Config) internal chainConfigs;

    modifier isOwner() {
        _isOwner();
        _;
    }

    modifier isSyncRouter(uint64 chainId) {
        require(msg.sender == chainConfigs[chainId].router, "NEQSR");
        _;
    }

    function _isOwner() internal virtual {}

    function getMainChainId() public pure returns (uint64) {
        return MAIN_CHAINID;
    }

    function getChainConfigs(
        uint64 chainId
    ) public view returns (Config memory) {
        return chainConfigs[chainId];
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