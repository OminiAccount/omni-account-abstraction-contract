// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {ISwapRouter02, IV3SwapRouter} from "../interfaces/uniswapv3/ISwapRouter02.sol";
import {IEntryPoint} from "../interfaces/zkaa/IEntryPoint.sol";
import {Event} from "../interfaces/Event.sol";
import {IUniswapV2Router02} from "../interfaces/uniswapv2/IUniswapV2Router02.sol";
import {BaseStruct} from "../interfaces/BaseStruct.sol";
import "../libraries/Error.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SyncRouter is
    VizingOmni,
    Ownable,
    ReentrancyGuard,
    Event,
    BaseStruct
{
    using SafeERC20 for IERC20;

    address public WETH;
    bytes1 private mode = 0x01;
    bytes private ZeroBytes = new bytes(0);
    address[] private routers;

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _vizingPad The VizingPad for this contract to interact with.
     * @param _WETH The owner address that will be set as the owner of the contract.
     */
    constructor(
        address _vizingPad,
        address _WETH
    ) VizingOmni(_vizingPad) Ownable(msg.sender) {
        WETH = _WETH;
    }

    mapping(uint64 => address) public MirrorEntryPoint;
    mapping(uint256 => bytes1) public LockWay;

    modifier onlyEntryPoint(uint64 chainId) {
        require(msg.sender == MirrorEntryPoint[chainId], "MEP");
        _;
    }

    modifier lock(uint256 way) {
        require(LockWay[way] == 0x00);
        _;
    }

    receive() external payable {}

    function setMirrorEntryPoint(
        uint64 chainId,
        address entryPoint
    ) external onlyOwner {
        MirrorEntryPoint[chainId] = entryPoint;
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

    function sendOmniMessage(
        CrossMessageParams calldata params
    ) external payable nonReentrant lock(0) {
        uint256 sendETHAmount;
        bytes memory payload;
        bytes memory newCrossParams;
        //only transfer eth
        if (params._hookMessageParams.way == 0) {
            CrossETHParams memory crossETH = abi.decode(params._hookMessageParams.packCrossParams, (CrossETHParams));
            sendETHAmount = crossETH.amount;
            newCrossParams = params._hookMessageParams.packCrossParams;
            //touch source chain uniswapV2
        } else if (params._hookMessageParams.way == 1) {
            CrossV2SwapParams memory crossV2 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV2SwapParams));
            //target chain swap (eth>other)
            if (crossV2.sourcePath[0] == address(0)) {
                sendETHAmount = crossV2.amountIn;
                V2SwapParams memory newV2SwapParams = V2SwapParams({
                    index: crossV2.targetIndex,
                    amountIn: crossV2.amountIn,
                    amountOutMin: 0,
                    path: crossV2.targetPath,
                    to: crossV2.to,
                    deadline: crossV2.deadline
                });
                payload = abi.encodeWithSignature(
                    "v2Swap((uint8,uint256,uint256,address[],address,uint256))",
                    newV2SwapParams
                );
            //source chain swap (other>eth)
            } else {
                V2SwapParams memory v2SwapParams = V2SwapParams({
                    index: crossV2.sourceIndex,
                    amountIn: crossV2.amountIn,
                    amountOutMin: crossV2.amountOutMin,
                    path: crossV2.targetPath,
                    to: address(this),
                    deadline: crossV2.deadline
                });
                sendETHAmount = this.v2Swap{value: v2SwapParams.amountIn}(
                    v2SwapParams
                );

            }
            CrossETHParams memory crossETH=CrossETHParams({
                amount: sendETHAmount,
                reciever: crossV2.to
            });
            newCrossParams = abi.encode(crossETH);
        //touch source chain uniswapV3
        } else if (params._hookMessageParams.way == 2) {
            CrossV3SwapParams memory crossV3 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV3SwapParams));
            //target chain swap (eth>other)
            if (crossV3.sourceChainTokenIn == address(0)) {
                sendETHAmount = crossV3.amountIn;
                V3SwapParams memory v3SwapParams = V3SwapParams({
                    index: crossV3.targetIndex,
                    fee: crossV3.targetFee,
                    sqrtPriceLimitX96: crossV3.targetSqrtPriceLimitX96,
                    tokenIn: address(0),
                    tokenOut: crossV3.targetChainTokenOut,
                    recipient: crossV3.recipient,
                    amountIn: crossV3.amountIn,
                    amountOutMinimum: crossV3.amountOutMinimum
                });
                payload = abi.encodeWithSignature(
                    "v3Swap((uint8,uint24,uint160,address,address,address,uint256,uint256))",
                    v3SwapParams
                );
            //source chain swap (other>eth)
            } else {
                V3SwapParams memory v3SwapParams = V3SwapParams({
                        index: crossV3.sourceIndex,
                        fee: crossV3.sourceFee,
                        sqrtPriceLimitX96: crossV3.sourceSqrtPriceLimitX96,
                        tokenIn: crossV3.sourceChainTokenIn,
                        tokenOut: address(0),
                        recipient: address(this),
                        amountIn: crossV3.amountIn,
                        amountOutMinimum: crossV3.amountOutMinimum
                    });
                sendETHAmount = this.v3Swap{value: v3SwapParams.amountIn}(
                    v3SwapParams
                );
            }
            CrossETHParams memory crossETH=CrossETHParams({
                amount: sendETHAmount,
                reciever: crossV3.recipient
            });
            newCrossParams = abi.encode(crossETH);
        } else {
            revert InvalidWay();
        }
        //repack
        CrossHookMessageParams memory newCrossHookMessageParams=CrossHookMessageParams({
            way: params._hookMessageParams.way,
            gasLimit: params._hookMessageParams.gasLimit,
            gasPrice: params._hookMessageParams.gasPrice,
            destChainId: params._hookMessageParams.destChainId,
            minArrivalTime: params._hookMessageParams.minArrivalTime,
            maxArrivalTime: params._hookMessageParams.maxArrivalTime,
            destContract: params._hookMessageParams.destContract,
            selectedRelayer: params._hookMessageParams.selectedRelayer,
            destChainExecuteUsedFee: params._hookMessageParams.destChainExecuteUsedFee,
            batchsMessage: params._hookMessageParams.batchsMessage,
            packCrossMessage: payload,  //The sending chain sends the instruction to the target chain after encode and executes the call
            packCrossParams: newCrossParams
        });
        // CrossMessageParams memory newCrossMessageParams=CrossMessageParams({
        //     _packedUserOperation: params._packedUserOperation,
        //     _hookMessageParams: newCrossHookMessageParams
        // });

        bytes memory encodedMessage = _packetMessage(
            mode,
            params._hookMessageParams.destContract,
            params._hookMessageParams.gasLimit,
            params._hookMessageParams.gasPrice,
            // abi.encode(newCrossMessageParams)
            abi.encode(CrossMessageParams({
                _packedUserOperation: params._packedUserOperation,
                _hookMessageParams: newCrossHookMessageParams
            }))
        );

        //vizing fee
        uint256 gasFee = LaunchPad.estimateGas(
            params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
            params._hookMessageParams.destChainId,
            ZeroBytes,
            encodedMessage
        );

        //check
        if (
            msg.value <
            gasFee +
                params._hookMessageParams.destChainExecuteUsedFee +
                sendETHAmount
        ) {
            revert InsufficientBalance();
        }

        LaunchPad.Launch{value: msg.value}(
            params._hookMessageParams.minArrivalTime,
            params._hookMessageParams.maxArrivalTime,
            params._hookMessageParams.selectedRelayer,
            msg.sender,
            params._hookMessageParams.destChainExecuteUsedFee,
            params._hookMessageParams.destChainId,
            ZeroBytes,
            encodedMessage
        );
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
        if (params.tokenIn == address(0)) {
            require(msg.value >= params.amountIn, "Send eth insufficient");
            _tokenIn = WETH;
            IWETH9(WETH).deposit{value: msg.value}();
        } else if (params.tokenOut == address(0)) {
            _tokenOut = WETH;
            receiver = address(this);
            IERC20(params.tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
        } else {
            IERC20(params.tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                params.amountIn
            );
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
            uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
            uint256 withdrawWETHAmount = wethBalance >= amountOut
                ? amountOut
                : wethBalance;
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
            IERC20(fromToken).safeTransferFrom(
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
            IERC20(fromToken).safeTransferFrom(
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

    function _receiveMessage(
        bytes32 messageId,
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual override {
        require(
            MirrorEntryPoint[srcChainId] == address(uint160(srcContract)),
            "Invalid contract"
        );
        CrossMessageParams memory _crossMessage = abi.decode(
            message,
            (CrossMessageParams)
        );
        bytes memory batchsMessage = abi.decode(
            _crossMessage._hookMessageParams.batchsMessage,
            (bytes)
        );
        PackedUserOperation[] memory userOps = abi.decode(
            batchsMessage,
            (PackedUserOperation[])
        );

        IEntryPoint(MirrorEntryPoint[uint64(block.chainid)]).syncBatches(
            userOps
        );
        
        bool suc;
        bytes memory resultData;
        CrossETHParams memory crossETHParams = abi.decode(_crossMessage._hookMessageParams.packCrossParams, (CrossETHParams));
        //receive eth
        if (_crossMessage._hookMessageParams.packCrossMessage.length == 0) {
            (suc, resultData) = crossETHParams.reciever.call{value: crossETHParams.amount}("");
            //Continue execution without throwing an error
            // require(suc, "Receive eth fail");
        } else {
            // Do hook
            (suc, resultData) = address(this).call{
                value: crossETHParams.amount
            }(_crossMessage._hookMessageParams.packCrossMessage);
            //Continue execution without throwing an error
            // require(suc,"Call hook fail");
        }
         emit ReceiveTouchHook(
                suc,
                resultData,
                _crossMessage._hookMessageParams.packCrossMessage
        );
    }

    function fetchOmniMessageFee(
        CrossMessageParams calldata params,
        uint256 sendETHAmount
    ) external view virtual returns (uint256 _gasFee) {
        bytes memory CrossMessage = abi.encode(params);

        bytes memory encodedMessage = _packetMessage(
            mode,
            params._hookMessageParams.destContract,
            params._hookMessageParams.gasLimit,
            params._hookMessageParams.gasPrice,
            CrossMessage
        );

        _gasFee = LaunchPad.estimateGas(
            params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
            params._hookMessageParams.destChainId,
            ZeroBytes,
            encodedMessage
        );
    }

    function routerLength() external view returns (uint256) {
        return routers.length;
    }

    function indexRouter(uint8 index) public view returns (address) {
        return routers[index];
    }
}
