#!/bin/sh

NODES_DIR=$HOME/nodes

if [ ! -d $NODES_DIR/node0 ]; then
    cored testnet --v 4 -o $NODES_DIR --chain-id obada-testnet  --keyring-backend=test --starting-ip-address 172.22.0.2
fi
