#!/bin/bash
source .env

forge create --rpc-url $LOCAL_RPC_URL --private-key $DEPLOY \
  --libraries src/library/GoldilocksPoseidon.sol:GoldilocksPoseidon:0x700b6A60ce7EaaEA56F065753d8dcB9653dbAD35 \
  Poseidon