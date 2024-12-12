//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {IUniswapV3Factory} from "../interfaces/uniswapv3/IUniswapFactory.sol";
import {ISwapRouter02, IV2SwapRouter, IV3SwapRouter} from "../interfaces/uniswapv3/ISwapRouter02.sol";
import {BaseStruct} from "../interfaces/BaseStruct.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {Event} from "../interfaces/Event.sol";
import {IUniswapV2Router02} from "../interfaces/uniswapv2/IUniswapV2Router02.sol";
import "../libraries/Error.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VizingSwap is Ownable, ReentrancyGuard, BaseStruct, Event{
    using SafeERC20 for IERC20;

    address public WETH;
    address public SyncRouter;
    address public Manager;
    address[] private routers;

    mapping(uint256 => bytes1) public LockWay;

    receive()external payable{}

    modifier lock(uint256 way) {
        require(LockWay[way] == 0x00,"Locked");
        _;
    }

    modifier onlySyncRouter {
        require(msg.sender == SyncRouter,"Non syncRouter");
        _;
    }

    modifier onlyManager {
        require(msg.sender == Manager, "Non Manager");
        _;
    }

    constructor(address _WETH)Ownable(msg.sender){
        WETH=_WETH;
        Manager=msg.sender;
    }

    function setManager(address _newManager) external onlyOwner {
        Manager=_newManager;
    }

    function setLock(uint256 _way, bytes1 _lockState) external onlyManager {
        LockWay[_way] = _lockState;
    }

    function initialize(address _syncRouter, address _newRouter) external onlyManager {
        SyncRouter = _syncRouter;
        routers.push(_newRouter);
    }

    function addRouter(address _newRouter) external onlyManager {
        routers.push(_newRouter);
    }

    function removeRouter(uint256 _indexOldRouter) external onlyManager {
        delete routers[_indexOldRouter];
    }

    /**
     * @notice public swap way.ETH=>Other token，params.tokenIn==address(0), Other token=>ETH, params.tokenOut=address(0)
     * The user needs to a the ERC20 token to the vizingswap contract
     * @param params user swap input V3SwapParams
     */
    function v3Swap(
        V3SwapParams calldata params
    ) public payable onlySyncRouter nonReentrant lock(1) returns (uint256) {
        address router = routers[params.index];
        address _tokenIn = params.tokenIn;
        address _tokenOut = params.tokenOut;
        address receiver = params.receiver;
        uint256 amountOut;
        if (params.tokenIn == address(0) && params.tokenOut != address(0)) {
            require(msg.value >= params.amountIn, "Send eth insufficient");
            _tokenIn = WETH;
            IWETH9(WETH).deposit{value: msg.value}();
        } else if (params.tokenIn != address(0) && params.tokenOut == address(0)) {
            _tokenOut = WETH;
            receiver = address(this);
            IERC20(params.tokenIn).transferFrom(
                params.sender, 
                address(this),
                params.amountIn
            );
        } else if (params.tokenIn != address(0) && params.tokenOut != address(0)){
            IERC20(params.tokenIn).transferFrom(
                params.sender,
                address(this),
                params.amountIn
            );
        }else {
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
            (bool suc, ) = params.receiver.call{value: withdrawWETHAmount}("");
            amountOut = withdrawWETHAmount;
            require(suc, "Withdraw eth fail");
        }
        emit VizingSwapEvent(
            params.sender,
            params.tokenIn,
            params.tokenOut,
            params.receiver,
            params.amountIn,
            amountOut
        );
        return amountOut;
    }

    function v2Swap(
        V2SwapParams calldata params
    ) public payable onlySyncRouter nonReentrant lock(2) returns (uint256) {
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
                params.sender, 
                address(this),
                params.amountIn
            );
            IERC20(fromToken).approve(router, params.amountIn);
            outputData = IUniswapV2Router02(router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.receiver,
                block.timestamp + params.deadline
            );
            //other swap eth
        } else if (fromToken != address(0) && toToken == address(0)) {
            newPath[newPath.length - 1] = WETH;
            IERC20(fromToken).transferFrom(
                params.sender,
                address(this),
                params.amountIn
            );
            IERC20(fromToken).approve(router, params.amountIn);
            outputData = IUniswapV2Router02(router).swapExactTokensForETH(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.receiver,
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
                params.receiver,
                block.timestamp + params.deadline
            );
        } else {
            revert InvalidPath();
        }
        emit VizingSwapEvent(
            params.sender,
            fromToken,
            toToken,
            params.receiver,
            params.amountIn,
            outputData[1]
        );
        return outputData[1];
    }

    /**
     * @notice Return tokens mistakenly sent by users, or remove shit coins
     * @param token  refund token (eth=address(0))
     * @param receiver token receiver
     * @param amount  receive amount
     */
    function refund(address token, address receiver, uint256 amount) external onlyManager {
        if(token==address(0)){
            uint256 balance=address(this).balance;
            require(balance>0 && balance>=amount,"Insufficient balance");
            (bool suc,)=receiver.call{value: amount}("");
            require(suc,"Refund eth fail");
        }else{
            IERC20(token).transfer(receiver, amount);
        }
        emit RefundEvent(token, receiver, amount);
    }

    function _getTokenBalance(address _token,address _user)private view returns(uint256 _balance){
        _balance = IERC20(_token).balanceOf(_user);
    }

    function getTokenBalance(address token,address user)external view returns(uint256){
        return _getTokenBalance(token,user);
    }

    function routerLength()external view returns(uint256){
        return routers.length;
    }

    function indexRouter(uint256 index)public view returns(address){
        return routers[index];
    }

}