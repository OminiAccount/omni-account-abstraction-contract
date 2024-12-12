// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./core/BaseAccount.sol";
import "./libraries/Helpers.sol";
import "./TokenCallbackHandler.sol";

/**
 * ZK vizing account.
 *  this is vizing account.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract ZKVizingAccount is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable
{
    error InsufficientBalance();

    address public owner;

    IEntryPoint private immutable _entryPoint;

    event ZKVizingAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            "only owner"
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     * @param dest destination address to call
     * @param value the value to pass in this call
     * @param func the calldata to pass in this call
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     * @param dest an array of destination addresses
     * @param value an array of values to pass to each call. can be zero-length for no-value calls
     * @param func an array of calldata to pass to each call
     */
    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(
            dest.length == func.length &&
                (value.length == 0 || value.length == func.length),
            "wrong array lengths"
        );
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of ZKVizingAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     * @param anOwner the owner (signer) of this account
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        emit ZKVizingAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            "account: not Owner or EntryPoint"
        );
    }

    /// implement template method of BaseAccount
    function _validateOwner(
        address _owner
    ) internal virtual override returns (bool validationResult) {
        if (owner != _owner) {
            return false;
        }
        return true;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function getPreGasBalance() external view returns (uint256) {
        return entryPoint().getPreGasBalanceInfo(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function depositGas(uint256 nonce) public payable {
        entryPoint().submitDepositOperation{value: msg.value}(msg.value, nonce);
    }

    function depositRemote(
        uint256 nonce,
        uint256 amount,
        uint256 gasAmount,
        uint256 destChainExecuteUsedFee,
        uint24 gasLimit,
        uint64 gasPrice,
        uint64 minArrivalTime,
        uint64 maxArrivalTime,
        address selectedRelayer
    ) public payable {
        require(msg.value >= amount + destChainExecuteUsedFee);
        if (gasAmount != 0) {
            this.depositGasRemote{value: gasAmount + destChainExecuteUsedFee}(
                nonce,
                gasAmount,
                destChainExecuteUsedFee,
                gasLimit,
                gasPrice,
                minArrivalTime,
                maxArrivalTime,
                selectedRelayer
            );
        }
    }

    /**
     * deposit Gas to vizing from other chains
     */
    function depositGasRemote(
        uint256 nonce,
        uint256 amount,
        uint256 destChainExecuteUsedFee,
        uint24 gasLimit,
        uint64 gasPrice,
        uint64 minArrivalTime,
        uint64 maxArrivalTime,
        address selectedRelayer
    ) external payable {
        // msg.value = crossFee+amount+destChainExecuteOpFee
        require(msg.value >= amount + destChainExecuteUsedFee);

        bytes memory data = abi.encodeCall(
            entryPoint().submitDepositOperationByRemote,
            (address(this), amount, nonce)
        );

        // destChainExecuteUsedFee include amount
        destChainExecuteUsedFee += amount;
        CrossMessageParams memory params;
        CrossETHParams memory crossETH;
        crossETH.amount = amount;
        params._hookMessageParams.way = 255;
        params._hookMessageParams.gasLimit = gasLimit;
        params._hookMessageParams.gasPrice = gasPrice;
        params._hookMessageParams.destChainId = entryPoint().getMainChainId();
        params._hookMessageParams.minArrivalTime = minArrivalTime;
        params._hookMessageParams.maxArrivalTime = maxArrivalTime;
        params._hookMessageParams.destContract = entryPoint()
            .getChainConfigs(params._hookMessageParams.destChainId)
            .router;
        params._hookMessageParams.selectedRelayer = selectedRelayer;
        params
            ._hookMessageParams
            .destChainExecuteUsedFee = destChainExecuteUsedFee;
        params._hookMessageParams.packCrossMessage = data;
        params._hookMessageParams.packCrossParams = abi.encode(crossETH);

        entryPoint().sendDepositOperation{value: msg.value}(params);
    }

    /**
     * withdraw value from the account's deposit
     * @param amount to withdraw
     * @notice Currently, only owner's own withdrawal is supported.
     * After the circuit data is updated later, withdrawTo fields can be added.
     */
    function withdrawGas(uint256 amount) public onlyOwner {
        entryPoint().submitWithdrawOperation(amount);
    }

    // function redeemGas(uint256 amount, uint256 nonce) public onlyOwner {
    //     entryPoint().redeemGasOperation(amount, nonce);
    // }

    function withdraw(uint256 amount) external onlyOwner {
        if (amount > address(this).balance) {
            revert InsufficientBalance();
        }
        _call(msg.sender, amount, "");
    }

    /**
     * Withdraw the balance of AA account from vizing to other chains
     */
    function withdrawRemote(
        uint256 nonce,
        uint64 destChainId,
        uint256 amount,
        address receiver,
        uint256 destChainExecuteUsedFee,
        uint24 gasLimit,
        uint64 gasPrice,
        uint64 minArrivalTime,
        uint64 maxArrivalTime,
        address selectedRelayer
    ) external onlyOwner {
        CrossMessageParams memory params;

        // pack CrossETHParams
        CrossETHParams memory crossETH;
        crossETH.amount = amount;
        crossETH.reciever = receiver;

        params._hookMessageParams.way = 254;
        params._hookMessageParams.gasLimit = gasLimit;
        params._hookMessageParams.gasPrice = gasPrice;
        params._hookMessageParams.destChainId = destChainId;
        params._hookMessageParams.minArrivalTime = minArrivalTime;
        params._hookMessageParams.maxArrivalTime = maxArrivalTime;
        params._hookMessageParams.destContract = entryPoint()
            .getChainConfigs(params._hookMessageParams.destChainId)
            .router;
        params._hookMessageParams.selectedRelayer = selectedRelayer;
        params
            ._hookMessageParams
            .destChainExecuteUsedFee = destChainExecuteUsedFee;
        params._hookMessageParams.packCrossParams = abi.encode(crossETH);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyOwner();
    }
}