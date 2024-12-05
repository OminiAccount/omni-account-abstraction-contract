// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

import "./BaseStruct.sol";

interface ISyncRouter is BaseStruct {
    function fetchOmniMessageFee(
        CrossParams calldata params
    ) external view returns (uint256);

    function crossMessage(CrossParams calldata params) external payable;
}
