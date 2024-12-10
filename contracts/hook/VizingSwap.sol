//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {IUniswapV3Factory} from "../interfaces/uniswapv3/IUniswapFactory.sol";
import {ISwapRouter02, IV2SwapRouter, IV3SwapRouter} from "../interfaces/uniswapv3/ISwapRouter02.sol";
import {IVizingSwap} from "../interfaces/hook/IVizingSwap.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {Event} from "../interfaces/Event.sol";
import {BaseStruct} from "../interfaces/core/BaseStruct.sol";
import {IUniswapV2Router02} from "../interfaces/uniswapv2/IUniswapV2Router02.sol";
import "../libraries/Error.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VizingSwap is Ownable, ReentrancyGuard, BaseStruct, Event {
    using SafeERC20 for IERC20;

    address private WETH;
    address[] private routers;

    mapping(uint256 => bytes1) public LockWay;

    receive() external payable {}

    modifier lock(uint256 way) {
        require(LockWay[way] == 0x00, "Locked");
        _;
    }

    constructor(address _WETH) Ownable(msg.sender) {
        WETH = _WETH;
    }

    function setLock(uint256 _way, bytes1 _lockState) external onlyOwner {
        LockWay[_way] = _lockState;
    }

    function addRouter(address _newRouter) external onlyOwner {
        routers.push(_newRouter);
    }

    function removeRouter(uint256 _indexOldRouter) external onlyOwner {
        delete routers[_indexOldRouter];
    }

    /**
     * @notice public swap way.ETH=>Other token，params.tokenIn==address(0), Other token=>ETH, params.tokenOut=address(0)
     * @param params user swap input V3SwapParams
     */
    function v3Swap(
        V3SwapParams calldata params
    ) public payable nonReentrant lock(1) returns (uint256) {
        address router = routers[params.index];
        address _tokenIn = params.tokenIn;
        address _tokenOut = params.tokenOut;
        address receiver = params.recipient;
        uint256 amountOut;
        if (params.tokenIn == address(0) && params.tokenOut != address(0)) {
            require(msg.value >= params.amountIn, "Send eth insufficient");
            _tokenIn = WETH;
            IWETH9(WETH).deposit{value: msg.value}();
        } else if (
            params.tokenIn != address(0) && params.tokenOut == address(0)
        ) {
            _tokenOut = WETH;
            receiver = address(this);
            IERC20(params.tokenIn).transferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
        } else if (
            params.tokenIn != address(0) && params.tokenOut != address(0)
        ) {
            IERC20(params.tokenIn).transferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
        } else {
            revert InvalidPath();
        }
        IERC20(_tokenIn).approve(router, params.amountIn);

        IV3SwapRouter.ExactInputSingleParams memory v3Params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: params.fee,
                recipient: receiver,
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            });
        amountOut = ISwapRouter02(router).exactInputSingle(v3Params);
        if (_tokenOut == WETH) {
            uint256 WETHBalance = IERC20(WETH).balanceOf(address(this));
            uint256 withdrawWETHAmount = WETHBalance >= amountOut
                ? amountOut
                : WETHBalance;
            IWETH9(WETH).withdraw(withdrawWETHAmount);
            (bool suc, ) = params.recipient.call{value: withdrawWETHAmount}("");
            amountOut = withdrawWETHAmount;
            require(suc, "Withdraw eth fail");
        }
        emit VizingSwapEvent(
            msg.sender,
            params.tokenIn,
            params.tokenOut,
            params.recipient,
            params.amountIn,
            amountOut
        );
        return amountOut;
    }

    function v2Swap(
        V2SwapParams calldata params
    ) public payable nonReentrant lock(2) returns (uint256) {
        address router = routers[params.index];
        address fromToken = params.path[0];
        address toToken = params.path[params.path.length - 1];
        uint256[] memory outputData;
        address[] memory newPath = new address[](params.path.length);
        for (uint256 i; i < params.path.length; i++) {
            newPath[i] = params.path[i];
        }
        //other swap other
        if (fromToken != address(0) && toToken != address(0)) {
            IERC20(fromToken).transferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
            IERC20(fromToken).approve(router, params.amountIn);
            outputData = IUniswapV2Router02(router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
            //other swap eth
        } else if (fromToken != address(0) && toToken == address(0)) {
            newPath[newPath.length - 1] = WETH;
            IERC20(fromToken).transferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
            IERC20(fromToken).approve(router, params.amountIn);
            outputData = IUniswapV2Router02(router).swapExactTokensForETH(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
            //eth swap other
        } else if (fromToken == address(0) && toToken != address(0)) {
            newPath[0] = WETH;
            outputData = IUniswapV2Router02(router).swapExactETHForTokens{
                value: msg.value
            }(
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
        } else {
            revert InvalidPath();
        }
        emit VizingSwapEvent(
            msg.sender,
            fromToken,
            toToken,
            params.to,
            params.amountIn,
            outputData[1]
        );
        return outputData[1];
    }

    // function callV3Swap(V3SwapParams calldata params) external payable {
    //     bool success;
    //     if(params.tokenIn!=address(0)){
    //         (success,) = address(this).delegatecall(
    //             abi.encodeWithSignature("v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))",
    //                 params
    //             )
    //         );
    //     }else{
    //         require(msg.value>=params.amountIn,"ETH Amount");
    //         (success,) = address(this).call{value: msg.value}(
    //             abi.encodeWithSignature("v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))",
    //                 params
    //             )
    //         );
    //     }
    //     require(success, "v3Swap call failed");
    // }

    function _getTokenBalance(
        address _token,
        address _user
    ) private view returns (uint256 _balance) {
        _balance = IERC20(_token).balanceOf(_user);
    }

    function getTokenBalance(
        address token,
        address user
    ) external view returns (uint256) {
        return _getTokenBalance(token, user);
    }

    function routerLength() external view returns (uint256) {
        return routers.length;
    }

    function indexRouter(uint256 index) public view returns (address) {
        return routers[index];
    }
}
