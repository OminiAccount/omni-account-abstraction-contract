// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    uint256 dstCoeffGas = 50;
    uint256 dstConGas = 200000;

    address sepoliaSyncRouter = 0x48fb990fC322fA9D2D7E27D31D3D2Eed5B287702;
    address arbitrumSepoliaSyncRouter =
        0x4eceb80D4E35e5cCf70304aF5f2C5a216896AEED;

    address sepoliaEntryPoint = 0x23B707665cf102990F2Abe3741C1D97679901b5f;
    address arbitrumSepoliaEntryPoint =
        0x9CaCAE416A2B59136C3a382d80D9A55d3Cebe292;

    address sepoliaFactory = 0xD1C6d74C8248E2a3f5b32A7cfF1d78e69A9520E2;
    address arbitrumSepoliaFactory = 0x48fb990fC322fA9D2D7E27D31D3D2Eed5B287702;

    address verifier = 0xd5b83E42E902DcB759db3Cd22A6e62CEAb74e6c4;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00154ebb5f415f85b771d59138e4f62d774c3cbc3226773825e185ff870b3419;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
