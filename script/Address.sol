// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0xd69063398e6aF0bd4C248837828Fa871C6cF94c1;
    address arbitrumSepoliaSyncRouter =
        0xd69063398e6aF0bd4C248837828Fa871C6cF94c1;

    address sepoliaEntryPoint = 0xe141262039fd65FbcdB8Fe9266de94e3e3a7e192;
    address arbitrumSepoliaEntryPoint =
        0xe141262039fd65FbcdB8Fe9266de94e3e3a7e192;

    address sepoliaFactory = 0x741e62226F2a96EfA566E409Bda68Dea474a8B23;
    address arbitrumSepoliaFactory = 0x741e62226F2a96EfA566E409Bda68Dea474a8B23;

    address verifier = 0x0917B6b9b20A8Ee9fD27bd5e85D88BEb6Af2e039;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00a57166823f1a260e65c2beb10d35f9f7baff2095916719b529313185ed5729;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5;
}
