// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./ZKVizingAccount.sol";

/**
 * A factory contract for ZKVizingAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract ZKVizingAccountFactory is Ownable {
    error AccountAlreadyCreated();

    struct UserZKVizingAccountInfo {
        uint256 userId;
        address zkVizingAccount;
    }

    event AccountCreated(address indexed account, address owner);

    ZKVizingAccount public immutable accountImplementation;

    address internal bundler;

    mapping(address => UserZKVizingAccountInfo)
        private _UserZKVizingAccountInfo;

    modifier onlyBundler() {
        require(msg.sender == bundler);
        _;
    }

    constructor(IEntryPoint _entryPoint) Ownable(msg.sender) {
        accountImplementation = new ZKVizingAccount(_entryPoint);
    }

    function updateBundler(address _bundler) external onlyOwner {
        bundler = _bundler;
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        address owner,
        uint256 userId
    ) public onlyBundler returns (ZKVizingAccount ret) {
        if (_UserZKVizingAccountInfo[owner].zkVizingAccount != address(0)) {
            revert AccountAlreadyCreated();
        }

        ret = ZKVizingAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(userId)}(
                    address(accountImplementation),
                    abi.encodeCall(ZKVizingAccount.initialize, (owner))
                )
            )
        );
        address zkVizingAccountAddress = address(ret);
        require(zkVizingAccountAddress != address(0));
        _UserZKVizingAccountInfo[owner] = UserZKVizingAccountInfo({
            userId: userId,
            zkVizingAccount: zkVizingAccountAddress
        });
        emit AccountCreated(zkVizingAccountAddress, owner);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAccountAddress(
        address owner,
        uint256 userId
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(userId),
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode,
                        abi.encode(
                            address(accountImplementation),
                            abi.encodeCall(ZKVizingAccount.initialize, (owner))
                        )
                    )
                )
            );
    }

    function getUserAccountInfo(
        address _owner
    ) external view returns (UserZKVizingAccountInfo memory) {
        return _UserZKVizingAccountInfo[_owner];
    }
}
