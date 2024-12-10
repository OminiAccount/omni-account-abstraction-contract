//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;
import {BaseStruct} from "../core/BaseStruct.sol";

interface IVizingSwap is BaseStruct {
    function v3Swap(
        V3SwapParams calldata params
    ) external payable returns (uint256);

    function v2Swap(
        V2SwapParams calldata params
    ) external payable returns (uint256);
}
