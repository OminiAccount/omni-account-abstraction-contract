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

    address sepoliaFactory = 0xC65d497690b7747dE9C2Ceb844Ee877DaEDAe425;
    address arbitrumSepoliaFactory = 0xC65d497690b7747dE9C2Ceb844Ee877DaEDAe425;

    address verifier = 0x6C70Cf2d1deFe71aBa6eD5da4e7360943157a6FE;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x0080002da3d759722129c5fabd878c0f90fbbfc8156d3007d3b546da4e5658d9;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
