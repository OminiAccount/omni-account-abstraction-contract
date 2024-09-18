// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0x1969cf6AAD9F4C13346338b4186A071511a1F6dA;
    address arbitrumSepoliaSyncRouter =
        0x1969cf6AAD9F4C13346338b4186A071511a1F6dA;

    address sepoliaEntryPoint = 0x5b899E99Bdde4109769b9e5d005A134832Dc5116;
    address arbitrumSepoliaEntryPoint =
        0x5b899E99Bdde4109769b9e5d005A134832Dc5116;

    address sepoliaFactory = 0xf87766a699E8357D7a72ed2C5f7D1E1163b38e9F;
    address arbitrumSepoliaFactory = 0xf87766a699E8357D7a72ed2C5f7D1E1163b38e9F;

    address verifier = 0x745C68b09519d26C9E18Ea713fEf332d567121FB;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00a57166823f1a260e65c2beb10d35f9f7baff2095916719b529313185ed5729;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0x96f3088fC6E3e4C4535441f5Bc4d69C4eF3FE9c5;
}
