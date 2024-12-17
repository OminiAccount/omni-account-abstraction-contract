// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.24;

import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IWETH9} from "../../interfaces/IWETH9.sol";
import {ISwapRouter02, IV3SwapRouter} from "../../interfaces/uniswapv3/ISwapRouter02.sol";
import {IEntryPoint} from "../../interfaces/core/IEntryPoint.sol";
import {Event} from "../../interfaces/Event.sol";
import {IUniswapV2Router02} from "../../interfaces/uniswapv2/IUniswapV2Router02.sol";
import {ISyncRouter} from "../../interfaces/core/ISyncRouter.sol";
import {IVizingSwap} from "../../interfaces/hook/IVizingSwap.sol";
import "../../libraries/Error.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


// Todo: The cross-chain module is separated from the business module.
contract SyncRouter is
    VizingOmni,
    Ownable,
    ReentrancyGuard,
    Event,
    ISyncRouter
{
    using SafeERC20 for IERC20;

    uint256 public OrderId;
    address public WETH;
    address public Hook;

    bytes1 private mode = 0x01;
    bytes private additionParams = new bytes(0);

    uint24 public defaultGaslimit = 500000;
    uint64 public defaultGasPrice = 1 gwei;
    uint64 public override minArrivalTime;
    uint64 public override maxArrivalTime;
    address public thisRelayer;

    /**
     * @dev Constructs a new BatchSend contract instance.
     * @param _vizingPad The VizingPad for this contract to interact with.
     * @param _WETH The owner address that will be set as the owner of the contract.
     * @param _Hook VizingSwap address
     */
    constructor(
        address _vizingPad,
        address _WETH,
        address _Hook
    ) VizingOmni(_vizingPad) Ownable(msg.sender) {
        WETH = _WETH;
        Hook = _Hook;
    }

    mapping(uint64 => address) public MirrorEntryPoint;
    mapping(uint256 => bytes1) public LockWay;

    mapping(bytes => uint8) public DataExcecuteNumber;

    modifier onlyEntryPoint(uint64 chainId) {
        require(msg.sender == MirrorEntryPoint[chainId], "MEP");
        _;
    }

    receive() external payable {}

    /**
     * @notice owner set chain entryPoint
     * @param chainId chainid
     * @param entryPoint chain entryPoint
     */
    function setMirrorEntryPoint(
        uint64 chainId,
        address entryPoint
    ) external onlyOwner {
        MirrorEntryPoint[chainId] = entryPoint;
    }

    function changeDefaultSet(
        uint24 newGaslimit,
        uint64 newGasPrice,
        address newRelayer
    ) external onlyOwner {
        defaultGaslimit = newGaslimit;
        defaultGasPrice = newGasPrice;
        thisRelayer = newRelayer;
    }

    function sendOmniMessage(
        uint64 destChainId,
        address destContract,
        uint256 destChainExecuteUsedFee, // Amount that the target chain needs to spend to execute userop
        PackedUserOperation[] calldata userOperations
    ) external payable onlyEntryPoint(uint64(block.chainid)) {
        bytes memory encodedMessage = _packetMessage(
            mode,
            destContract,
            defaultGaslimit,
            defaultGasPrice,
            abi.encode(userOperations)
        );

        uint256 gasFee = fetchOmniMessageFee(
            destChainId,
            destContract,
            destChainExecuteUsedFee,
            userOperations
        );

        require(msg.value >= gasFee + destChainExecuteUsedFee);

        // step 4: send Omni-Message 2 Vizing Launch Pad
        LaunchPad.Launch{value: msg.value}(
            minArrivalTime,
            maxArrivalTime,
            thisRelayer,
            msg.sender,
            destChainExecuteUsedFee,
            destChainId,
            additionParams,
            encodedMessage
        );
    }

    function sendUserOmniMessage(
        CrossMessageParams calldata cmp
    ) external payable nonReentrant {
        (
            uint256 sendETHAmount,
            bytes memory encodeOmniMessage
        ) = getUserOmniEncodeMessage(cmp);

        bytes memory encodedMessage = _packetMessage(
            mode,
            cmp._hookMessageParams.destContract,
            cmp._hookMessageParams.gasLimit,
            cmp._hookMessageParams.gasPrice,
            encodeOmniMessage
        );

        //vizing fee
        uint256 gasFee = LaunchPad.estimateGas(
            cmp._hookMessageParams.destChainExecuteUsedFee + sendETHAmount,
            cmp._hookMessageParams.destChainId,
            additionParams,
            encodedMessage
        );

        //check
        require(
            msg.value >=
                gasFee +
                    cmp._hookMessageParams.destChainExecuteUsedFee +
                    sendETHAmount,
            "Send eth Insufficient"
        );

        LaunchPad.Launch{value: msg.value}(
            cmp._hookMessageParams.minArrivalTime,
            cmp._hookMessageParams.maxArrivalTime,
            cmp._hookMessageParams.selectedRelayer,
            msg.sender,
            cmp._hookMessageParams.destChainExecuteUsedFee + sendETHAmount, //if transfer eth to target chain
            cmp._hookMessageParams.destChainId,
            additionParams,
            encodedMessage
        );
    }

    //What does encode do? --TODO
    function getUserOmniEncodeMessage(
        CrossMessageParams memory cmp
    ) public view returns (uint256, bytes memory) {
        uint256 sendETHAmount;
        bytes memory payload;
        bytes memory newCrossParams;
        //eth transfer on different chains（Should I send eth directly through vizing?）  --TODO
        if (cmp._hookMessageParams.way == 0) {
            CrossETHParams memory crossETH;
            if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                0
            ) {
                crossETH = abi.decode(
                    cmp._packedUserOperation[0].exec.callData,
                    (CrossETHParams)
                );
                newCrossParams = cmp._packedUserOperation[0].exec.callData;
            } else if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                1 &&
                cmp._packedUserOperation[0].innerExec.callData.length > 0
            ) {
                crossETH = abi.decode(
                    cmp._packedUserOperation[0].innerExec.callData,
                    (CrossETHParams)
                );
                newCrossParams = cmp._packedUserOperation[0].innerExec.callData;
            } else {
                revert ExecutionCompleted();
            }
            sendETHAmount = crossETH.amount;
            payload = cmp._hookMessageParams.packCrossMessage;
            //uniswap v2
        } else if (cmp._hookMessageParams.way == 1) {
            V2SwapParams memory v2SwapParams;
            if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                0
            ) {
                v2SwapParams = abi.decode(
                    cmp._packedUserOperation[0].exec.callData,
                    (V2SwapParams)
                );
            } else if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                1 &&
                cmp._packedUserOperation[0].innerExec.callData.length > 0
            ) {
                v2SwapParams = abi.decode(
                    cmp._packedUserOperation[0].innerExec.callData,
                    (V2SwapParams)
                );
            } else {
                revert ExecutionCompleted();
            }
            payload = abi.encodeCall(IVizingSwap(Hook).v2Swap, v2SwapParams);
            //uniswap v3
        } else if (cmp._hookMessageParams.way == 2) {
            V3SwapParams memory v3SwapParams;
            if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                0
            ) {
                v3SwapParams = abi.decode(
                    cmp._packedUserOperation[0].exec.callData,
                    (V3SwapParams)
                );
            } else if (
                DataExcecuteNumber[cmp._packedUserOperation[0].exec.callData] ==
                1 &&
                cmp._packedUserOperation[0].innerExec.callData.length > 0
            ) {
                v3SwapParams = abi.decode(
                    cmp._packedUserOperation[0].innerExec.callData,
                    (V3SwapParams)
                );
            } else {
                revert ExecutionCompleted();
            }
            payload = abi.encodeCall(IVizingSwap(Hook).v3Swap, v3SwapParams);
        } else if (cmp._hookMessageParams.way == 254) {
            // withdraw remote
            CrossETHParams memory crossETH = abi.decode(
                cmp._hookMessageParams.packCrossParams,
                (CrossETHParams)
            );
            sendETHAmount = crossETH.amount;
            newCrossParams = cmp._hookMessageParams.packCrossParams;
            payload = cmp._hookMessageParams.packCrossMessage;
        } else if (cmp._hookMessageParams.way == 255) {
            // deposit gas remote
            CrossETHParams memory crossETH = abi.decode(
                cmp._hookMessageParams.packCrossParams,
                (CrossETHParams)
            );
            sendETHAmount = crossETH.amount;
            newCrossParams = cmp._hookMessageParams.packCrossParams;
            payload = cmp._hookMessageParams.packCrossMessage;
        } else {
           
        }

        //repack
        CrossHookMessageParams
            memory newCrossHookMessageParams = CrossHookMessageParams({
                way: cmp._hookMessageParams.way,
                gasLimit: cmp._hookMessageParams.gasLimit,
                gasPrice: cmp._hookMessageParams.gasPrice,
                destChainId: cmp._hookMessageParams.destChainId,
                minArrivalTime: cmp._hookMessageParams.minArrivalTime,
                maxArrivalTime: cmp._hookMessageParams.maxArrivalTime,
                destContract: cmp._hookMessageParams.destContract,
                selectedRelayer: cmp._hookMessageParams.selectedRelayer,
                destChainExecuteUsedFee: cmp
                    ._hookMessageParams
                    .destChainExecuteUsedFee,
                batchsMessage: cmp._hookMessageParams.batchsMessage,
                packCrossMessage: payload, //The sending chain sends the instruction to the target chain after encode and executes the call
                packCrossParams: newCrossParams
            });

        bytes memory crossGGData = abi.encode(
            CrossMessageParams({
                _packedUserOperation: cmp._packedUserOperation,
                _hookMessageParams: newCrossHookMessageParams
            })
        );

        return (sendETHAmount, crossGGData);
    }

    function fetchUserOmniMessageFee(
        CrossMessageParams calldata params
    ) external view virtual returns (uint256 _gasFee) {
        bytes memory CrossMessage = abi.encode(params);

        CrossETHParams memory crossETH = abi.decode(
            params._hookMessageParams.packCrossParams,
            (CrossETHParams)
        );
        uint256 sendETHAmount = crossETH.amount;

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
            additionParams,
            encodedMessage
        );
    }

    function testReceiveMessage(bytes calldata message) external payable {
        CrossMessageParams memory _crossMessage = abi.decode(
            message,
            (CrossMessageParams)
        );

        if (_crossMessage._packedUserOperation.length != 0) {
            IEntryPoint(MirrorEntryPoint[uint64(block.chainid)]).syncBatches(
                _crossMessage._packedUserOperation
            );
        }

        bool suc;
        bytes memory resultData;
        CrossETHParams memory crossETHParams = abi.decode(
            _crossMessage._hookMessageParams.packCrossParams,
            (CrossETHParams)
        );

        // withdraw remote
        if (_crossMessage._hookMessageParams.way == 254) {
            (suc, resultData) = crossETHParams.reciever.call{
                value: crossETHParams.amount
            }("");
        } else if (_crossMessage._hookMessageParams.way == 255) {
            (suc, resultData) = MirrorEntryPoint[uint64(block.chainid)].call{
                value: crossETHParams.amount
            }(_crossMessage._hookMessageParams.packCrossMessage);
        } else if (_crossMessage._hookMessageParams.way == 0) {
            //receive eth  
            (suc, resultData) = crossETHParams.reciever.call{
                value: crossETHParams.amount
            }("");
        } else {
            // Do hook
            (suc, resultData) = address(this).call{
                value: crossETHParams.amount
            }(_crossMessage._hookMessageParams.packCrossMessage);
        }

        emit ReceiveTouchHook(
            suc,
            resultData,
            _crossMessage._hookMessageParams.packCrossMessage
        );
    }

    function _receiveMessage(
        bytes32 messageId,
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual override {
        address srcSyncRouter=IEntryPoint(MirrorEntryPoint[srcChainId]).getChainConfigs(srcChainId).router;
        require(srcSyncRouter == address(uint160(srcContract)),"Invalid contract");

        CrossMessageParams memory _crossMessage = abi.decode(
            message,
            (CrossMessageParams)
        );

        if (_crossMessage._packedUserOperation.length != 0) {
            IEntryPoint(MirrorEntryPoint[uint64(block.chainid)]).syncBatches(
                _crossMessage._packedUserOperation
            );
        }

        bool suc;
        bytes memory resultData;
        CrossETHParams memory crossETHParams = abi.decode(
            _crossMessage._hookMessageParams.packCrossParams,
            (CrossETHParams)
        );

        // deposit remote
        if (_crossMessage._hookMessageParams.way == 255) {
            (suc, resultData) = MirrorEntryPoint[uint64(block.chainid)].call{
                value: crossETHParams.amount +
                    _crossMessage._hookMessageParams.destChainExecuteUsedFee
            }(_crossMessage._hookMessageParams.packCrossMessage);
        } else if (
            _crossMessage._hookMessageParams.way == 0 ||
            _crossMessage._hookMessageParams.way == 254
        ) {
            //receive eth 
            (suc, resultData) = crossETHParams.reciever.call{
                value: crossETHParams.amount
            }("");
        } else {
            // Do hook
            (suc, resultData) = address(this).call{
                value: crossETHParams.amount
            }(_crossMessage._hookMessageParams.packCrossMessage);
        }

        emit ReceiveTouchHook(
            suc,
            resultData,
            _crossMessage._hookMessageParams.packCrossMessage
        );
    }

    function fetchOmniMessageFee(
        uint64 destChainId,
        address destContract,
        uint256 destChainUsedFee,
        PackedUserOperation[] calldata userOperations
    ) public view virtual returns (uint256) {
        bytes memory userOperationsMessage = abi.encode(userOperations);
        bytes memory encodedMessage = _packetMessage(
            mode,
            destContract,
            defaultGaslimit,
            defaultGasPrice,
            userOperationsMessage
        );

        return
            LaunchPad.estimateGas(
                destChainUsedFee,
                destChainId,
                additionParams,
                encodedMessage
            );
    }
}