//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {BaseStruct} from "../interfaces/BaseStruct.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '../interfaces/hook/IVizingSwap.sol';

contract TestCall is BaseStruct{
    using SafeERC20 for IERC20;

    receive()external payable{}

    event CallEvent(bool suc,bytes amount);
    function callV3Swap1(V3SwapParams calldata params, address vizingSwapAddress) external payable {
        if(params.tokenIn!=address(0)){
            IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
            IERC20(params.tokenIn).approve(vizingSwapAddress, params.amountIn);
        }else{
            require(msg.value>=params.amountIn,"Send eth fail");
        }
        (bool success, bytes memory data) = vizingSwapAddress.call{value: msg.value}(
            abi.encodeWithSignature("v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))", 
                params
            )
        );
        require(success, "v3Swap call failed");
        emit CallEvent(success,data);
    }

    function callV3Swap2(V3SwapParams calldata params, address vizingSwapAddress) external payable {
        if(params.tokenIn!=address(0)){
            IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
            IERC20(params.tokenIn).approve(vizingSwapAddress, params.amountIn);
        }else{
            require(msg.value>=params.amountIn,"ETH Amount");
        }
        bytes4 select=bytes4(
                keccak256(
                    "v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))"
                )
        );
        (bool success, bytes memory data) = vizingSwapAddress.call{value: msg.value}(
            abi.encodeWithSelector(select, 
                params
            )
        );
        require(success, "v3Swap call failed");
        emit CallEvent(success,data);
    }

    function callV3Swap3(V3SwapParams calldata params, address vizingSwapAddress) external payable {
        bool success;
        bytes memory data;
        if(params.tokenIn!=address(0)){
            IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
            IERC20(params.tokenIn).approve(vizingSwapAddress, params.amountIn);
        }else{
            require(msg.value>=params.amountIn,"ETH Amount");
        }
        (success, data) = vizingSwapAddress.call{value: msg.value}(
                abi.encodeCall(
                    IVizingSwap(vizingSwapAddress).v3Swap, 
                    params
                )
        );
        require(success, "v3Swap call failed");
        emit CallEvent(success,data);
    }

    function decodeData(bytes memory data)external view returns(uint256){
        uint256 amount=abi.decode(data, (uint256));
        return amount;
    }
}