// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {ISwapRouter02, IV3SwapRouter} from "../../interfaces/uniswapv3/ISwapRouter02.sol";
import {IEntryPoint, PackedUserOperation} from "../../interfaces/zkaa/IEntryPoint.sol";
import {IZKVizingAAEvent} from "../../interfaces/IZKVizingAAEvent.sol";
import {IZKVizingAAError} from "../../interfaces/IZKVizingAAError.sol";
import {IZKVizingAAStruct} from "../../interfaces/IZKVizingAAStruct.sol";
import {IUniswapV2Router02} from "../../interfaces/uniswapv2/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SyncRouter is VizingOmni, Ownable, ReentrancyGuard, IZKVizingAAStruct, IZKVizingAAEvent, IZKVizingAAError{
    using SafeERC20 for IERC20;

    address public WETH;
    bytes1 private mode = 0x01;
    address[] private routers;

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _vizingPad The VizingPad for this contract to interact with.
     * @param _owner The owner address that will be set as the owner of the contract.
     * @param _routers Routers[0]=uniswap v3 router, Routers[1]=uniswap v2 router
     */
    constructor(
        address _vizingPad,
        address _owner,
        address[] memory _routers
    ) VizingOmni(_vizingPad) Ownable(_owner) {
        for(uint256 i; i<_routers.length; i++){
            routers.push(_routers[i]);
        }
    }

    mapping(uint64 => address) public mirrorEntryPoint;
    mapping(uint256 => bytes1) public LockWay;

    modifier onlyEntryPoint(uint64 chainId) {
        require(msg.sender == mirrorEntryPoint[chainId], "MEP");
        _;
    }

    modifier lock(uint256 way){
        require(LockWay[way] == 0x00);
        _;
    }
    
    receive() external payable {}

    function setMirrorEntryPoint(
        uint64 chainId,
        address entryPoint
    ) external onlyOwner {
        mirrorEntryPoint[chainId] = entryPoint;
    }

    /**
     * @notice owner set lock
     * @param _way lock crossMessage==0, uniswapV3==1, uniswapV2==2
     * @param _lockState _lockState=0x00==unlock, _lockState!=0x00==locked
     */
    function setLock(uint256 _way, bytes1 _lockState) external onlyOwner {
        LockWay[_way] = _lockState;
    }

    /**
     * @notice owner add new swap router
     * @param _newRouter push new router to routers[]
     */
    function addRouter(address _newRouter) external onlyOwner {
        routers.push(_newRouter);
    }

    /**
     * @notice owner remove swap router
     * @param _indexOldRouter index routers[]
     */
    function removeRouter(uint8 _indexOldRouter) external onlyOwner {
        delete routers[_indexOldRouter];
    }

    function crossMessage(
        CrossParams calldata params
    ) public payable nonReentrant lock(0) {
        bytes memory message = abi.encode(params.batchsMessage, params.packCrossMessage, params.way);
        bytes memory encodedMessage = _packetMessage(
            mode,
            params.destContract,
            params.gasLimit,
            params.gasPrice,
            message
        );

        uint256 gasFee = fetchOmniMessageFee(params);

        require(msg.value >= gasFee + params.destChainUsedFee);

        LaunchPad.Launch{value: msg.value}(
            params.minArrivalTime,
            params.maxArrivalTime,
            params.selectedRelayer,
            msg.sender,
            params.destChainUsedFee,
            params.destChainId,
            new bytes(0),
            encodedMessage
        );
    }

    /**
     * @notice public swap way.ETH=>Other token，params.tokenIn==address(0), Other token=>ETH, params.tokenOut=address(0)
     * @param params user swap input V3SwapParams
     */
    function v3Swap(V3SwapParams calldata params)public payable nonReentrant lock(1) returns(uint256){
        address router=routers[params.index];
        address _tokenIn=params.tokenIn;
        address _tokenOut=params.tokenOut;
        address receiver=params.recipient;
        uint256 amountOut;
        if(params.tokenIn == address(0)){
            require(msg.value >= params.amountIn,"Send eth insufficient");
            _tokenIn=WETH;
            IWETH9(WETH).deposit{value: msg.value}();
        }else if(params.tokenOut == address(0)){
            _tokenOut=WETH;
            receiver=address(this);
            IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        }else{
            IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amountIn);
        }
        IERC20(_tokenIn).approve(router, params.amountIn);

        IV3SwapRouter.ExactInputSingleParams memory v3Params=IV3SwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: params.fee,
            recipient: receiver,
            amountIn: params.amountIn,
            amountOutMinimum: params.amountOutMinimum,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96
        });
        amountOut=ISwapRouter02(router).exactInputSingle(v3Params);
        if(_tokenOut == WETH){
            uint256 wethBalance=IERC20(WETH).balanceOf(address(this));
            uint256 withdrawWETHAmount=wethBalance>=amountOut?amountOut:wethBalance;
            IWETH9(WETH).withdraw(withdrawWETHAmount);
            (bool suc,)=params.recipient.call{value: withdrawWETHAmount}("");
            amountOut=withdrawWETHAmount;
            require(suc, "Withdraw eth fail");
        }
        emit VizingSwapEvent(msg.sender, params.tokenIn, params.tokenOut, params.recipient, params.amountIn, amountOut);
        return amountOut;
    }

    function v2Swap(V2SwapParams calldata params)public payable nonReentrant lock(2) returns(uint256){
        address router=routers[params.index];
        address fromToken=params.path[0];
        address toToken=params.path[params.path.length-1];
        uint256[] memory outputData;
        address[] memory newPath = new address[](params.path.length);
        for(uint256 i;i<params.path.length;i++){
            newPath[i]=params.path[i];
        }
        //other swap other
        if(fromToken!=address(0) && toToken!=address(0)){
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), params.amountIn);
            IERC20(fromToken).approve(router, params.amountIn);
            outputData=IUniswapV2Router02(router).swapExactTokensForTokens(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
        //other swap eth
        }else if(fromToken!=address(0) && toToken==address(0)){
            newPath[newPath.length-1]=WETH;
            IERC20(fromToken).safeTransferFrom(msg.sender, address(this), params.amountIn);
            IERC20(fromToken).approve(router, params.amountIn);
            outputData=IUniswapV2Router02(router).swapExactTokensForETH(
                params.amountIn,
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
        //eth swap other
        }else if(fromToken==address(0) && toToken!=address(0)){
            newPath[0]=WETH;
            outputData=IUniswapV2Router02(router).swapExactETHForTokens{value: msg.value}(
                params.amountOutMin,
                params.path,
                params.to,
                block.timestamp + params.deadline
            );
        }else{
            revert InvalidPath();
        }
        emit VizingSwapEvent(msg.sender, fromToken, toToken, params.to, params.amountIn, outputData[1]);
        return outputData[1];
    }

    function _receiveMessage(
        bytes32 messageId,
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual override {
        require(mirrorEntryPoint[srcChainId] == address(uint160(srcContract)),"Invalid contract");
        (bytes memory batchsMessage, bytes memory packCrossMessage, uint8 way) = abi.decode(message, (bytes, bytes, uint8));
        PackedUserOperation[] memory userOps = abi.decode(
            batchsMessage,
            (PackedUserOperation[])
        );
        
        IEntryPoint(mirrorEntryPoint[uint64(block.chainid)]).syncBatch(userOps);
        uint256 amountOut;
        if(way == 0){
        
        //v2 swap
        }else if(way == 1){
            V2SwapParams memory v2SwapParams = abi.decode(packCrossMessage, (V2SwapParams));
            try this.v2Swap(v2SwapParams) returns (uint256 result){
                amountOut = result;
            }catch {
                amountOut = 0;
            }
        //v3 swap
        }else if(way ==2){
            V3SwapParams memory v3SwapParams = abi.decode(packCrossMessage, (V3SwapParams));
            try this.v3Swap(v3SwapParams) returns (uint256 result){
                amountOut = result;
            }catch {
                amountOut = 0;
            }
        }else{
            revert InvalidWay();
        }

    }

    function fetchOmniMessageFee(
        CrossParams calldata params
    ) public view returns (uint256) {
        bytes memory message = abi.encode(params.batchsMessage, params.packCrossMessage);
        bytes memory encodedMessage = _packetMessage(
            mode,
            params.destContract,
            params.gasLimit,
            params.gasPrice,
            message
        );
        return
            LaunchPad.estimateGas(
                params.destChainUsedFee,
                params.destChainId,
                new bytes(0),
                encodedMessage
            );
    }

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

    function indexRouter(uint8 index) public view returns (address) {
        return routers[index];
    }
}
