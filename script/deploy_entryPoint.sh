#!/bin/bash
source .env

forge script script/deployEntryPoint_0.s.sol --broadcast  --legacy -vvvv --rpc-url $LOCAL_RPC_URL