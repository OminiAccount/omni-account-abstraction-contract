//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {BaseStruct} from "../interfaces/BaseStruct.sol";

contract TestCall is BaseStruct{
    
    event CallEvent(uint256 amount);
    function callV3Swap(V3SwapParams calldata params, address syncRouterAddress) external payable {
        (bool success, bytes memory data) = syncRouterAddress.call{value: msg.value}(
            abi.encodeWithSignature("v3Swap((address,address,uint24,address,uint256,uint256,uint160,uint8))", params)
        );
        require(success, "v3Swap call failed");

        uint256 amountOut = abi.decode(data, (uint256));
        emit CallEvent(amountOut);
    }
}