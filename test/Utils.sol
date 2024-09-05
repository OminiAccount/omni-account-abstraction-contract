// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;
import "forge-std/Test.sol";
import "contracts/SimpleAccount.sol";

contract Utils is Test {
    function encodeTransferCalldata(
        address to,
        uint256 amount
    ) public pure returns (bytes memory data) {
        return
            abi.encodeWithSelector(
                SimpleAccount.execute.selector,
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
}
