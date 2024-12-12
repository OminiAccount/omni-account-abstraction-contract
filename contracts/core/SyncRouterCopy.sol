// // SPDX-License-Identifier: GPL-3.0-only
// pragma solidity ^0.8.24;

// import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {IWETH9} from "../interfaces/IWETH9.sol";
// import {ISwapRouter02, IV3SwapRouter} from "../interfaces/uniswapv3/ISwapRouter02.sol";
// import {IEntryPoint} from "../interfaces/core/IEntryPoint.sol";
// import {Event} from "../interfaces/Event.sol";
// import {IUniswapV2Router02} from "../interfaces/uniswapv2/IUniswapV2Router02.sol";
// import {BaseStruct} from "../interfaces/BaseStruct.sol";
// import {IVizingSwap} from "../interfaces/hook/IVizingSwap.sol";
// import "../libraries/Error.sol";

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// contract SyncRouter is
//     VizingOmni,
//     Ownable,
//     ReentrancyGuard,
//     Event,
//     BaseStruct
// {
//     using SafeERC20 for IERC20;
    
//     bytes1 private mode = 0x01;
//     address public WETH;
//     address public Hook;
//     bytes private additionParams = new bytes(0);

//     uint24 public defaultGaslimit = 50000;
//     uint64 public defaultGasPrice = 1 gwei;
//     uint64 public immutable override minArrivalTime;
//     uint64 public immutable override maxArrivalTime;
//     address public immutable override selectedRelayer;
    
//     /**
//      * @dev Constructs a new BatchSend contract instance.
//      * @param _vizingPad The VizingPad for this contract to interact with.
//      * @param _WETH The owner address that will be set as the owner of the contract.
//      * @param _Hook VizingSwap address
//      */
//     constructor(
//         address _vizingPad,
//         address _WETH,
//         address _Hook
//     ) VizingOmni(_vizingPad) Ownable(msg.sender) {
//         WETH = _WETH;
//         Hook = _Hook;
//     }

//     mapping(uint64 => address) public MirrorEntryPoint;
//     mapping(uint256 => bytes1) public LockWay;

//     modifier onlyEntryPoint(uint64 chainId) {
//         require(msg.sender == MirrorEntryPoint[chainId], "MEP");
//         _;
//     }

//     modifier lock(uint256 way) {
//         require(LockWay[way] == 0x00);
//         _;
//     }

//     receive() external payable {}

//     /**
//      * @notice owner set chain entryPoint
//      * @param chainId chainid
//      * @param entryPoint chain entryPoint
//      */
//     function setMirrorEntryPoint(
//         uint64 chainId,
//         address entryPoint
//     ) external onlyOwner {
//         MirrorEntryPoint[chainId] = entryPoint;
//     }

//     /**
//      * @notice owner set lock
//      * @param _way lock crossMessage==0, uniswapV3==1, uniswapV2==2
//      * @param _lockState _lockState=0x00==unlock, _lockState!=0x00==locked
//      */
//     function setLock(uint256 _way, bytes1 _lockState) external onlyOwner {
//         LockWay[_way] = _lockState;
//     }

//     /**
//      * @notice owner change new hook
//      * @param _newHook new hook address
//      */
//     function changeHook(address _newHook) external onlyOwner {
//         Hook = _newHook;
//     }

//     function sendOmniMessage(
//         uint64 destChainId,
//         address destContract,
//         uint256 destChainExecuteUsedFee, // Amount that the target chain needs to spend to execute userop
//         PackedUserOperation[] calldata userOperations
//     ) external payable onlyEntryPoint(uint64(block.chainid)) {
//         bytes memory encodedMessage = _packetMessage(
//             mode,
//             destContract,
//             defaultGaslimit,
//             defaultGasPrice,
//             abi.encode(userOperations)
//         );

//         uint256 gasFee = fetchOmniMessageFee(
//             destChainId,
//             destContract,
//             destChainExecuteUsedFee,
//             userOperations
//         );

//         require(msg.value >= gasFee + destChainExecuteUsedFee);

//         // step 4: send Omni-Message 2 Vizing Launch Pad
//         LaunchPad.Launch{value: msg.value}(
//             minArrivalTime,
//             maxArrivalTime,
//             selectedRelayer,
//             msg.sender,
//             destChainExecuteUsedFee,
//             destChainId,
//             additionParams,
//             encodedMessage
//         );
//     }

//     function sendUserOmniMessage(
//         CrossMessageParams calldata params
//     ) external payable nonReentrant lock(0) {
//         uint256 sendETHAmount;
//         bytes memory payload;
//         bytes memory newCrossParams;
//         //only transfer eth
//         if (params._hookMessageParams.way == 0) {
//             CrossETHParams memory crossETH = abi.decode(params._hookMessageParams.packCrossParams, (CrossETHParams));
//             sendETHAmount = crossETH.amount;
//             newCrossParams = params._hookMessageParams.packCrossParams;
//             //touch source chain uniswapV2
//         } else if (params._hookMessageParams.way == 1) {
//             CrossV2SwapParams memory crossV2 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV2SwapParams));
//             address[] memory newPath;
//             //target chain swap (eth>other)
//             if (crossV2.sourceToken == address(0)) {
//                 sendETHAmount = crossV2.amountIn;
//                 newPath[0]=address(0);
//                 newPath[1]=crossV2.targetToken;
//                 V2SwapParams memory newV2SwapParams = V2SwapParams({
//                     index: crossV2.targetIndex,
//                     amountIn: crossV2.amountIn,
//                     amountOutMin: 0,
//                     path: newPath,
//                     to: crossV2.to,
//                     deadline: crossV2.deadline
//                 });
//                 payload = abi.encodeCall(
//                     IVizingSwap(Hook).v2Swap,
//                     newV2SwapParams
//                 );
//             //source chain swap (other>eth)
//             } else {
//                 newPath[0]=crossV2.sourceToken;
//                 newPath[1]=address(0);
//                 V2SwapParams memory v2SwapParams = V2SwapParams({
//                     index: crossV2.sourceIndex,
//                     amountIn: crossV2.amountIn,
//                     amountOutMin: crossV2.amountOutMin,
//                     path: newPath,
//                     to: address(this),
//                     deadline: crossV2.deadline
//                 });
//                 IERC20(crossV2.sourceToken).safeTransferFrom(msg.sender, address(this), crossV2.amountIn);
//                 IERC20(crossV2.sourceToken).approve(Hook, crossV2.amountIn);
//                 sendETHAmount = IVizingSwap(Hook).v2Swap(v2SwapParams);
//             }
//             CrossETHParams memory crossETH=CrossETHParams({
//                 amount: sendETHAmount,
//                 reciever: crossV2.to
//             });
//             newCrossParams = abi.encode(crossETH);
//         //touch source chain uniswapV3
//         } else if (params._hookMessageParams.way == 2) {
//             CrossV3SwapParams memory crossV3 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV3SwapParams));
//             //target chain swap (eth>other)
//             if (crossV3.sourceChainTokenIn == address(0)) {
//                 sendETHAmount = crossV3.amountIn;
//                 V3SwapParams memory v3SwapParams = V3SwapParams({
//                     index: crossV3.targetIndex,
//                     fee: crossV3.targetFee,
//                     sqrtPriceLimitX96: crossV3.targetSqrtPriceLimitX96,
//                     tokenIn: address(0),
//                     tokenOut: crossV3.targetChainTokenOut,
//                     recipient: crossV3.recipient,
//                     amountIn: crossV3.amountIn,
//                     amountOutMinimum: crossV3.amountOutMinimum
//                 });
//                 payload = abi.encodeCall(
//                     IVizingSwap(Hook).v3Swap,
//                     v3SwapParams
//                 );
                
//             //source chain swap (other>eth)
//             } else {
//                 V3SwapParams memory v3SwapParams = V3SwapParams({
//                         index: crossV3.sourceIndex,
//                         fee: crossV3.sourceFee,
//                         sqrtPriceLimitX96: crossV3.sourceSqrtPriceLimitX96,
//                         tokenIn: crossV3.sourceChainTokenIn,
//                         tokenOut: address(0),
//                         recipient: address(this),
//                         amountIn: crossV3.amountIn,
//                         amountOutMinimum: crossV3.amountOutMinimum
//                     });
//                 IERC20(v3SwapParams.tokenIn).safeTransferFrom(msg.sender, address(this), v3SwapParams.amountIn);
//                 IERC20(v3SwapParams.tokenIn).approve(Hook, v3SwapParams.amountIn);
//                 sendETHAmount = IVizingSwap(Hook).v3Swap(v3SwapParams);
//             }
//             CrossETHParams memory crossETH=CrossETHParams({
//                 amount: sendETHAmount,
//                 reciever: crossV3.recipient
//             });
//             newCrossParams = abi.encode(crossETH);
//         } else {
//             revert InvalidWay();
//         }
//         //repack
//         CrossHookMessageParams memory newCrossHookMessageParams=CrossHookMessageParams({
//             way: params._hookMessageParams.way,
//             gasLimit: params._hookMessageParams.gasLimit,
//             gasPrice: params._hookMessageParams.gasPrice,
//             destChainId: params._hookMessageParams.destChainId,
//             minArrivalTime: params._hookMessageParams.minArrivalTime,
//             maxArrivalTime: params._hookMessageParams.maxArrivalTime,
//             destContract: params._hookMessageParams.destContract,
//             selectedRelayer: params._hookMessageParams.selectedRelayer,
//             destChainExecuteUsedFee: params._hookMessageParams.destChainExecuteUsedFee,
//             batchsMessage: params._hookMessageParams.batchsMessage,
//             packCrossMessage: payload,  //The sending chain sends the instruction to the target chain after encode and executes the call
//             packCrossParams: newCrossParams
//         });
//         // CrossMessageParams memory newCrossMessageParams=CrossMessageParams({
//         //     _packedUserOperation: params._packedUserOperation,
//         //     _hookMessageParams: newCrossHookMessageParams
//         // });

//         bytes memory encodedMessage = _packetMessage(
//             mode,
//             params._hookMessageParams.destContract,
//             params._hookMessageParams.gasLimit,
//             params._hookMessageParams.gasPrice,
//             // abi.encode(newCrossMessageParams)
//             abi.encode(CrossMessageParams({
//                 _packedUserOperation: params._packedUserOperation,
//                 _hookMessageParams: newCrossHookMessageParams
//             }))
//         );

//         //vizing fee
//         uint256 gasFee = LaunchPad.estimateGas(
//             params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
//             params._hookMessageParams.destChainId,
//             additionParams,
//             encodedMessage
//         );

//         //check
//         require(msg.value >= gasFee + params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,"Send eth insufficient");

//         LaunchPad.Launch{value: msg.value}(
//             params._hookMessageParams.minArrivalTime,
//             params._hookMessageParams.maxArrivalTime,
//             params._hookMessageParams.selectedRelayer,
//             msg.sender,
//             params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
//             params._hookMessageParams.destChainId,
//             additionParams,
//             encodedMessage
//         );
//     }

//     function _receiveMessage(
//         bytes32 messageId,
//         uint64 srcChainId,
//         uint256 srcContract,
//         bytes calldata message
//     ) internal virtual override {
//         require(
//             MirrorEntryPoint[srcChainId] == address(uint160(srcContract)),
//             "Invalid contract"
//         );
//         CrossMessageParams memory _crossMessage = abi.decode(
//             message,
//             (CrossMessageParams)
//         );
//         bytes memory batchsMessage = abi.decode(
//             _crossMessage._hookMessageParams.batchsMessage,
//             (bytes)
//         );
//         PackedUserOperation[] memory userOps = abi.decode(
//             batchsMessage,
//             (PackedUserOperation[])
//         );

//         IEntryPoint(MirrorEntryPoint[uint64(block.chainid)]).syncBatches(
//             userOps
//         );
        
//         bool suc;
//         bytes memory resultData;
//         CrossETHParams memory crossETHParams = abi.decode(_crossMessage._hookMessageParams.packCrossParams, (CrossETHParams));
//         //receive eth
//         if (_crossMessage._hookMessageParams.packCrossMessage.length == 0) {
//             (suc, resultData) = crossETHParams.reciever.call{value: crossETHParams.amount}("");
//             //Continue execution without throwing an error
//             // require(suc, "Receive eth fail");
//         } else {
//             // Do hook
//             (suc, resultData) = address(this).call{
//                 value: crossETHParams.amount
//             }(_crossMessage._hookMessageParams.packCrossMessage);
//             //Continue execution without throwing an error
//             // require(suc,"Call hook fail");
//         }
//          emit ReceiveTouchHook(
//                 suc,
//                 resultData,
//                 _crossMessage._hookMessageParams.packCrossMessage
//         );
//     }

//     function fetchUserOmniMessageFee(
//         CrossMessageParams calldata params
//     ) external view virtual returns (uint256 _totalTransferETHAmount) {
//         bytes memory CrossMessage = abi.encode(params);
//         uint256 sendETHAmount;

//         if (params._hookMessageParams.way == 0) {
//             CrossETHParams memory crossETH = abi.decode(params._hookMessageParams.packCrossParams, (CrossETHParams));
//             sendETHAmount = crossETH.amount;
//             //touch source chain uniswapV2
//         } else if (params._hookMessageParams.way == 1) {
//             CrossV2SwapParams memory crossV2 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV2SwapParams));
//             //target chain swap (eth>other)
//             if (crossV2.sourceToken == address(0)) {
//                 sendETHAmount = crossV2.amountIn;
//             }
//         //touch source chain uniswapV3
//         } else if (params._hookMessageParams.way == 2) {
//             CrossV3SwapParams memory crossV3 = abi.decode(params._hookMessageParams.packCrossParams, (CrossV3SwapParams));
//             //target chain swap (eth>other)
//             if (crossV3.sourceChainTokenIn == address(0)) {
//                 sendETHAmount = crossV3.amountIn;
//             } 
//         } else {
//             revert InvalidWay();
//         }

//         bytes memory encodedMessage = _packetMessage(
//             mode,
//             params._hookMessageParams.destContract,
//             params._hookMessageParams.gasLimit,
//             params._hookMessageParams.gasPrice,
//             CrossMessage
//         );
//         uint256 _gasFee = LaunchPad.estimateGas(
//             params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
//             params._hookMessageParams.destChainId,
//             additionParams,
//             encodedMessage
//         );
//         _totalTransferETHAmount=_gasFee + params._hookMessageParams.destChainExecuteUsedFee + sendETHAmount;
//     }

//     function fetchOmniMessageFee(
//         uint64 destChainId,
//         address destContract,
//         uint256 destChainUsedFee,
//         PackedUserOperation[] calldata userOperations
//     ) public view virtual returns (uint256) {
//         bytes memory userOperationsMessage = abi.encode(userOperations);
//         bytes memory encodedMessage = _packetMessage(
//             mode,
//             destContract,
//             defaultGaslimit,
//             defaultGasPrice,
//             userOperationsMessage
//         );

//         return
//             LaunchPad.estimateGas(
//                 destChainUsedFee,
//                 destChainId,
//                 additionParams,
//                 encodedMessage
//             );
//     }

    
// }
