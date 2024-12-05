// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./ZKVizingAccount.sol";

/**
 * A sample factory contract for ZKVizingAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract ZKVizingAccountFactory {
    uint256 public UserId;

    event AccountCreated(address indexed account, address owner);
    ZKVizingAccount public immutable accountImplementation;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new ZKVizingAccount(_entryPoint);
    }

    function createAccount(
        address owner,
        uint256 salt
    ) public returns (ZKVizingAccount ret) {
        address addr = getAccountAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return ZKVizingAccount(payable(addr));
        }
        ret = ZKVizingAccount(
            payable(
                new ERC1967Proxy{salt: bytes32(salt)}(
                    address(accountImplementation),
                    abi.encodeCall(ZKVizingAccount.initialize, (owner))
                )
            )
        );

        emit AccountCreated(addr, owner);
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAccountAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(
                bytes32(salt),
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

}
