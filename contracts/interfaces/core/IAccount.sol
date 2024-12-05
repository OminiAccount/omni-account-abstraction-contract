// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./BaseStruct.sol";

interface IAccount is BaseStruct {
    /**
     * Validate user's owner is user's AA Contract owner.
     * @dev Must validate caller is the entryPoint.
     * @param _owner              - Owner of the account that generated this request.
     * @return validationResult   - Address verification result.
     */
    function validateUserOp(
        address _owner
    ) external returns (bool validationResult);
}
