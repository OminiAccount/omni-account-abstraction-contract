// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0x593F0C28209A3d1b8e8A14270b3B66c8920bc079;
    address arbitrumSepoliaSyncRouter =
        0x593F0C28209A3d1b8e8A14270b3B66c8920bc079;

    address sepoliaEntryPoint = 0x68d1f89FbD432E4f987366B2731DA5E18D767E02;
    address arbitrumSepoliaEntryPoint =
        0x68d1f89FbD432E4f987366B2731DA5E18D767E02;

    address sepoliaFactory = 0xED348FaCc1A49Ef26175C0619362B91298e9d2dB;
    address arbitrumSepoliaFactory = 0xED348FaCc1A49Ef26175C0619362B91298e9d2dB;

    address verifier = 0xdcA32db1CBFa716BA6996a929A9046e706C9cea5;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00a57166823f1a260e65c2beb10d35f9f7baff2095916719b529313185ed5729;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5;
}
