#!/bin/bash

forge inspect EntryPoint abi > ./compiled/EntryPoint/EntryPoint.abi && \
echo "EntryPoint ABI generated successfully."

forge inspect EntryPoint bytecode > ./compiled/EntryPoint/EntryPoint.bin && \
echo "EntryPoint Bytecode generated successfully."

forge inspect ZKVizingAccount abi > ./compiled/ZKVizingAccount/ZKVizingAccount.abi && \
echo "ZKVizingAccount ABI generated successfully."

forge inspect ZKVizingAccountFactory abi > ./compiled/ZKVizingAccountFactory/ZKVizingAccountFactory.abi && \
echo "ZKVizingAccountFactory ABI generated successfully."

forge inspect ZKVizingAccountFactory bytecode > ./compiled/ZKVizingAccountFactory/ZKVizingAccountFactory.bin && \
echo "ZKVizingAccountFactory Bytecode generated successfully."