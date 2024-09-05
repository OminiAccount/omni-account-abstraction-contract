#!/bin/bash
source .env

CHAIN1_RPC_URL=$SEPOLIA_RPC_URL CHAIN2_RPC_URL=$ARBITRUM_SEPOLIA_RPC_URL forge script script/deployEntryPoint.s.sol --broadcast  --legacy -vvvv