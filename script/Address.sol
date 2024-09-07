// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    address sepoliaSyncRouter = 0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;
    address arbitrumSepoliaSyncRouter =
        0x453C825cA5B8EdD85D531c3A3A01EE488670c2a7;

    address sepoliaEntryPoint = 0xD6D975bd319Acc8e9DEc3C50fD9C8b739eCBFd05;
    address arbitrumSepoliaEntryPoint =
        0xDB2D90cf05867cdF998aC29015c9Ac3e14A16c3C;

    address sepoliaFactory = 0x720e4ECAf0a6Bcd0622745248B004786899dBDeF;
    address arbitrumSepoliaFactory = 0xd5b83E42E902DcB759db3Cd22A6e62CEAb74e6c4;

    address verifier = 0xd5b83E42E902DcB759db3Cd22A6e62CEAb74e6c4;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00154ebb5f415f85b771d59138e4f62d774c3cbc3226773825e185ff870b3419;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xeac2F980834c3a27CFDD52a3073468A8aA07c12C;
}
