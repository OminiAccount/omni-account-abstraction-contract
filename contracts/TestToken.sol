// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    uint8 private thisDecimals;
    constructor(uint8 _thisDecimals,string memory name,string memory symbol)
        ERC20(name, symbol)
    {
        thisDecimals=_thisDecimals;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals()public override view returns(uint8){
        return thisDecimals;
    }
}