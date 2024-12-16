#!/bin/bash
source .env

CHAIN1_RPC_URL=$SEPOLIA_RPC_URL forge script script/deployVerifyManager.s.sol --broadcast  --legacy -vvvv