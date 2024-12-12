// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

interface IConfigManager {
    struct Config {
        address entryPoint;
        address router;
    }

    function getMainChainId() external view returns (uint64);

    function getChainConfigs(
        uint64 chainId
    ) external view returns (Config memory);
}