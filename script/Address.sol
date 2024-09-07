// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    address sepoliaSyncRouter = 0x3096b1217756C37AAF08A73E8120FA47Fb1C5CCE;
    address arbitrumSepoliaSyncRouter =
        0x3096b1217756C37AAF08A73E8120FA47Fb1C5CCE;

    address sepoliaEntryPoint = 0x38Aa7af83153706BD84D2D6FA66Bb4c7fA79EcE9;
    address arbitrumSepoliaEntryPoint =
        0x38Aa7af83153706BD84D2D6FA66Bb4c7fA79EcE9;

    address sepoliaFactory = 0x54eE76aD43e3A1dDbBBBA8c92F01cEcf09Ca3CfD;
    address arbitrumSepoliaFactory = 0x54eE76aD43e3A1dDbBBBA8c92F01cEcf09Ca3CfD;

    address verifier = 0xd5b83E42E902DcB759db3Cd22A6e62CEAb74e6c4;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00154ebb5f415f85b771d59138e4f62d774c3cbc3226773825e185ff870b3419;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
