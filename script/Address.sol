// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    address sepoliaSyncRouter = 0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;
    address arbitrumSepoliaSyncRouter =
        0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;

    address sepoliaEntryPoint = 0x5F2464f924b7D9166a870cCe9201AFBC2a2f151D;
    address arbitrumSepoliaEntryPoint =
        0x5F2464f924b7D9166a870cCe9201AFBC2a2f151D;

    address sepoliaFactory = 0x19B8495e7D3C0Ff16592f67745a0c887D3d60a4D;
    address arbitrumSepoliaFactory = 0x19B8495e7D3C0Ff16592f67745a0c887D3d60a4D;

    address verifier = 0xBCf327CD63FA62D25A5c261eCb05ee67Dc96fc2D;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x0027af29febf490e181e0586f4d6967e560e9c0c9b8e9c4b8959a8cb136ad980;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
