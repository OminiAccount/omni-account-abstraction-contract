// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0x4CF7d09b53EEe418bd0b7fc1568d1Dd923038005;
    address arbitrumSepoliaSyncRouter =
        0x4CF7d09b53EEe418bd0b7fc1568d1Dd923038005;

    address sepoliaEntryPoint = 0xe50DF7D2AB3a32F8BC228aD9a7681d7cf5039dFD;
    address arbitrumSepoliaEntryPoint =
        0xe50DF7D2AB3a32F8BC228aD9a7681d7cf5039dFD;

    address sepoliaFactory = 0x94C672Ab282511Cf20D0D44d5A1968401A1CC880;
    address arbitrumSepoliaFactory = 0x94C672Ab282511Cf20D0D44d5A1968401A1CC880;

    address verifier = 0x2de15470a3351ce35Edc2F0cB3B479840844bcAC;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00a57166823f1a260e65c2beb10d35f9f7baff2095916719b529313185ed5729;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5;
}
