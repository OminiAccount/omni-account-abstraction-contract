// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "contracts/ZKVizingAccount.sol";
import "contracts/core/EntryPoint.sol";
import "contracts/ZKVizingAccountFactory.sol";
import "contracts/interfaces/core/BaseStruct.sol";

contract Utils is BaseStruct, Test {
    function encodeTransferCalldata(
        address to,
        uint256 amount
    ) public pure returns (bytes memory data) {
        return
            abi.encodeWithSelector(
                ZKVizingAccount.execute.selector,
                to,
                amount,
                ""
            );
    }

    function packUints(
        uint256 high128,
        uint256 low128
    ) public pure returns (bytes32 packed) {
        require(high128 < 2 ** 128, "high128 exceeds 128 bits");
        require(low128 < 2 ** 128, "low128 exceeds 128 bits");

        // Combine high128 and low128 into a single bytes32 value
        packed = bytes32((high128 << 128) | low128);
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function getAccountInitCode(
        address owner,
        address factory,
        uint256 salt
    ) public pure returns (bytes memory) {
        bytes4 selector = ZKVizingAccountFactory.createAccount.selector;

        bytes memory encodedData = abi.encodeWithSelector(
            selector,
            owner,
            salt
        );

        return abi.encodePacked(factory, encodedData);
    }

    function deposit(
        address _owner,
        address payable account,
        uint256 _depositValue
    ) public returns (PackedUserOperation memory) {
        vm.recordLogs();
        vm.startPrank(_owner);
        uint256 beforePreGasBalance = ZKVizingAccount(account)
            .getPreGasBalance();
        ZKVizingAccount(account).depositGas{value: _depositValue}(1);
        uint256 afterPreGasBalance = ZKVizingAccount(account)
            .getPreGasBalance();
        assert(afterPreGasBalance == beforePreGasBalance + _depositValue);
        vm.stopPrank();
        Vm.Log[] memory entries = vm.getRecordedLogs();

        uint256 operationValue = abi.decode(entries[0].data, (uint256));
        bytes memory data = "";
        uint64 mainChainGasLimit = 0x30d40;
        uint64 destChainGasLimit = 0;
        uint64 zkVerificationGasLimit = 1700;
        uint64 mainChainGasPrice = 2_500_000_000;
        uint64 destChainGasPrice = 0;
        ExecData memory exec = ExecData(
            1,
            uint64(block.chainid),
            mainChainGasLimit,
            destChainGasLimit,
            zkVerificationGasLimit,
            mainChainGasPrice,
            destChainGasPrice,
            data
        );
        ExecData memory innerExec;
        PackedUserOperation memory account1OwnerUserOp = PackedUserOperation(
            0,
            1,
            operationValue,
            account,
            _owner,
            exec,
            innerExec
        );
        return account1OwnerUserOp;
    }

    function withdraw(
        address _owner,
        address payable account,
        uint256 _withdrawValue
    ) public returns (PackedUserOperation memory) {
        vm.startPrank(_owner);
        ZKVizingAccount(account).withdrawGas(_withdrawValue);
        vm.stopPrank();
        bytes memory data = "";
        uint64 mainChainGasLimit = 0x30d40;
        uint64 destChainGasLimit = 0;
        uint64 zkVerificationGasLimit = 1700;
        uint64 mainChainGasPrice = 2_500_000_000;
        uint64 destChainGasPrice = 0;
        ExecData memory exec = ExecData(
            2,
            uint64(block.chainid),
            mainChainGasLimit,
            destChainGasLimit,
            zkVerificationGasLimit,
            mainChainGasPrice,
            destChainGasPrice,
            data
        );
        ExecData memory innerExec;
        PackedUserOperation memory op = PackedUserOperation(
            0,
            2,
            _withdrawValue,
            account,
            _owner,
            exec,
            innerExec
        );
        return op;
    }
}
