// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0xd96EaD924D4bf2ACE86f6fa1C4a2d250094C2344;
    address arbitrumSepoliaSyncRouter =
        0x770a8Da6b1b07C23Ec246CF53e3B41eeAB190FcC;

    address sepoliaEntryPoint = 0xD42f2f03c89716aa5ca6109878E55932e1C66682;
    address arbitrumSepoliaEntryPoint =
        0x528cb96AA54A5BB4d28cBE6aef1725201d6cd10f;

    address sepoliaFactory = 0x334a1eF2f23b498d8C96d7584F5e05089565AeeC;
    address arbitrumSepoliaFactory = 0xE7C8751509112e3A77419D4d179d26b3f90C7cE3;

    address verifier = 0x9086CcCfb14BDA6C794563c13c02443EE3Eabce7;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00a57166823f1a260e65c2beb10d35f9f7baff2095916719b529313185ed5729;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
