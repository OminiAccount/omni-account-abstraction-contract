#!/bin/bash
source .env

forge create --rpc-url $LOCAL_RPC_URL --private-key $DEPLOY EntryPoint