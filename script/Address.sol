// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

contract AddressHelper {
    uint32 sepoliaEid = 40161;
    uint32 arbitrumSepoliaEid = 40231;

    address sepoliaSyncRouter = 0x1996a9faAE7b27D2cb36eF36A912b086F83b2d56;
    address arbitrumSepoliaSyncRouter =
        0x84E04a0f1DE51C6DcC145d3C3463B62B4cBE8152;

    address sepoliaEntryPoint = 0xA5e3E0E175Cf4c5E55527DcEB043e8DDe07c4E35;
    address arbitrumSepoliaEntryPoint =
        0x5f8AB9b43f0dd3661DD14d9F17787A7d12434d9D;

    address sepoliaFactory = 0xb39F7e2205ae32d1323E912357B4D83A530de347;
    address arbitrumSepoliaFactory = 0xC1cf05c0d1Bf848B918e59b48bF464776151F3A5;

    address verifier = 0x21C81909C1C8F2D1EDC67730B1967A2079b0D164;

    uint32[] sepoliaDstEids = [arbitrumSepoliaEid];

    address public sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e;
    bytes32 public aaProgramVKey =
        0x00562de31787f72cba4fffa5794e5500c92f40c0ac88e0cbb3b732460b096908;

    address endPoint = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address owner = 0xBC989fDe9e54cAd2aB4392Af6dF60f04873A033A;
}
