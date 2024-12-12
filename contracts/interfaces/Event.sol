// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

interface Event {


    /************************************************VzingSwap*********************************************************** */

    /**
     * Touch uniswap hook to swap
     * @param sender      - Touch swap sender.
     * @param tokenIn     - Touch swap input token(tokenIn==address(0)=>eth)
     * @param tokenOut    - Touch swap output token(tokenOut==address(0)=>eth)
     * @param receiver    - Touch swap output token to receiver
     * @param amountIn    - Touch swap input token amount
     * @param amountOut   - Touch swap output token amount
     */
    event VizingSwapEvent(
        address indexed sender,
        address indexed tokenIn,
        address indexed tokenOut,
        address receiver,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * Return user error funds event
     * @param token      - Touch swap sender.
     * @param receiver     - Touch swap input token(tokenIn==address(0)=>eth)
     * @param amount    - Touch swap output token(tokenOut==address(0)=>eth)
     */
    event RefundEvent(address indexed token, address indexed receiver, uint256 amount);

    /************************************************SyncRouter*********************************************************** */

    

    /**
     * Target chain touch hook
     * @param success      - Touch hook if success
     * @param data     - Touch call hook return data
     * @param packHookMessage    - source chain hook message
     */
    event ReceiveTouchHook(bool success, bytes data, bytes packHookMessage);

    /************************************************PreGasManager*********************************************************** */

    event DepositTicketAdded(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawTicketAdded(
        address indexed account,
        uint256 amount,
        uint256 timestamp
    );
    event DepositTicketDeleted(address indexed account, uint256 amount);
    event WithdrawTicketDeleted(address indexed account, uint256 amount);

    /************************************************EntryPoint*********************************************************** */

    /***
     * An event emitted after each successful request.
     * @param userOpHash    - Unique identifier for the request (hash its entire content, except signature).
     * @param sender        - The account that generates this request.
     * @param success       - True if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - Actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - Total gas used by this UserOperation (including preVerification, creation,
     *                        validation and execution).
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        bool success,
        uint256 actualGasCost,
        uint256 actualGasUsed
    );

    /**
     * Account "sender" was deployed.
     * @param userOpHash - The userOp that deployed this account. UserOperationEvent will follow.
     * @param sender     - The account that is deployed
     * @param factory    - The factory used to deploy this account (in the initCode)
     * @param paymaster  - The paymaster used by this UserOp
     */
    event AccountDeployed(
        bytes32 indexed userOpHash,
        address indexed sender,
        address factory,
        address paymaster
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        bytes revertReason
    );

    /**
     * An event emitted if the UserOperation Paymaster's "postOp" call reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event PostOpRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        bytes revertReason
    );

    /**
     * UserOp consumed more than prefund. The UserOperation is reverted, and no refund is made.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     */
    event UserOperationPrefundTooLow(
        bytes32 indexed userOpHash,
        address indexed sender
    );

    /**
     * An event emitted by handleOps(), before starting the execution loop.
     * Any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();
}