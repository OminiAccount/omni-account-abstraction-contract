// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./BaseStruct.sol";

interface ISyncRouter is BaseStruct {
    function fetchUserOmniMessageFee(
        CrossMessageParams calldata params
    ) external view returns (uint256);

    function sendUserOmniMessage(
        CrossMessageParams calldata params
    ) external payable;
}
