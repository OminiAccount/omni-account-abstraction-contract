#!/bin/bash
source .env
# NETMODE=TestNet forge script script/deployCoreContract.s.sol --broadcast --priority-gas-price 2000000000 -vvvv --rpc-url $ARBITRUM_SEPOLIA_RPC_URL && \
# NETMODE=TestNet forge script script/deployCoreContract.s.sol --broadcast --legacy -vvvv --rpc-url $OPTIMISM_SEPOLIA_RPC_URL && \
NETMODE=TestNet forge script script/deployCoreContract.s.sol --broadcast --legacy -vvvv --rpc-url $VIZING_SEPOLIA_RPC_URL 