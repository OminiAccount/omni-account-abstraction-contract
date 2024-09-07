// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    address sepoliaSyncRouter = 0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;
    address arbitrumSepoliaSyncRouter =
        0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;

    address sepoliaEntryPoint = 0x15dC63777584b1E04B3D0047FDd258C2C09B5a32;
    address arbitrumSepoliaEntryPoint =
        0x41EBE20Befde0f94B889D1633576e68605CEBC70;

    address sepoliaFactory = 0x1dC47415973e48cb4B8A01486BF684831f25EaF4;
    address arbitrumSepoliaFactory = 0x4Cee2b30384FA5e6eddB72247b80038D22AFccdb;

    address verifier = 0xd5b83E42E902DcB759db3Cd22A6e62CEAb74e6c4;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00154ebb5f415f85b771d59138e4f62d774c3cbc3226773825e185ff870b3419;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
